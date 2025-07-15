local Market = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Local Player
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local PopupUi = require(script.Parent.Popup)

local ViewportUtil = require(script.Parent.Util.Viewport)
local ItemUtility = require(ReplicatedStorage.Shared.Items.ItemUtility)
local InsightFrame = require(script.Parent.InsightFrame)
local SelectorsClass = require(script.Parent.Util.SelectorsClass)

-- Modules
local Trove = require(ReplicatedStorage.Packages.trove)
local ShopInfo = require(ReplicatedStorage.Shared.Services.ShopInfo)
local ItemInfo = require(ReplicatedStorage.Shared.Items.ItemInfo)
local AssetsDealer = require(ReplicatedStorage.Shared.AssetsDealer)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)
local CashUtility = require(ReplicatedStorage.Shared.Utility.CashUtility) 
local ButtonUtility = require(script.Parent.Util.ButtonUtility)

-- Ui Elements
local MainFrame = Ui.ShopGui:WaitForChild("MainFrame")
local MarketFrame = MainFrame:WaitForChild("MarketFrame")
local Content = MarketFrame:WaitForChild("Content")
local ItemTemplate = Content:WaitForChild("ItemTemplate"); ItemTemplate.Parent = script
local CategorySelectorsFrame = MarketFrame:WaitForChild("CategorySelectors")

-- Variables
local trove = Trove.new()
local currentCategory = "Dropper" -- Default category

local function setupLevelLock(uiItem, info)
    local locked = uiItem.Locked
    local lock = locked.Lock
    local levelLabel = lock.Level

    if info.levelRequirement and ClientPlayerData.Data.Level < info.levelRequirement then
        levelLabel.Text = "LVL " .. info.levelRequirement
        locked.Visible = true
    else
        levelLabel.Text = ""
        locked.Visible = false
    end
end

function Market.UpdateContent(itemCategory)
    trove:Clean()
    Ui.ClearFrame(Content)

    -- Gather all market items into a flat array for sorting
    local allMarketItems = {}
    for category, items in ShopInfo.Items do
        for itemName, info in items do
            if info.inMarket and (not itemCategory or category == itemCategory) then
                table.insert(allMarketItems, {
                    itemName = itemName,
                    info = info,
                    itemConfig = ItemUtility.GetItemConfig(itemName)
                })
            end
        end
    end

    -- Sort by price ascending, then by levelRequirement ascending if prices are equal
    table.sort(allMarketItems, function(a, b)
        if (a.info.price or 0) == (b.info.price or 0) then
            return (a.info.levelRequirement or 0) < (b.info.levelRequirement or 0)
        else
            return (a.info.price or 0) < (b.info.price or 0)
        end
    end)

    -- Display items in sorted order, setting LayoutOrder
    for i, entry in ipairs(allMarketItems) do
        local itemName = entry.itemName
        local info = entry.info
        local itemConfig = entry.itemConfig

        local uiItem = ItemTemplate:Clone()
        uiItem.Parent = Content
        uiItem.LayoutOrder = i
        uiItem.ItemName.Text = itemConfig.DisplayName or itemName
        uiItem.Price.Text = CashUtility.Format(info.price, {
            fullNumber = false,
            decimals = 0
        })
        setupLevelLock(uiItem, info)

        -- Add viewport for item preview (like Offers.lua)
        local viewport = ViewportUtil.CreateItemViewport(itemName)
        viewport.Parent = uiItem

        -- Buy button logic
        local buyButton = uiItem:FindFirstChild("BuyButton")
        if buyButton then
            trove:Connect(buyButton.MouseButton1Click, function()
                if uiItem.Locked.Visible then
                    Ui.PlaySound("Error")
                    return
                end
                buyButton.AutoButtonColor = false
                buyButton.Text = "Buying..."
                local success, result = pcall(function()
                    return ReplicatedStorage.Events.Market:InvokeServer({ itemName = itemName })
                end)
                if success and result == true then
                    Market.UpdateContent(currentCategory)
                else
                    Ui.PlaySound("Error")
                end
                buyButton.AutoButtonColor = true
            end)
        end

        trove:Connect(uiItem.MouseButton1Click, function()
            -- If it's locked, don't open the insight frame
            if uiItem.Locked.Visible then
                Ui.PlaySound("Error")
                return
            end

        InsightFrame.Open(itemConfig, itemName, info.price, info.levelRequirement, itemConfig.Rarity, function()
                -- On confirm purchase from insight frame
                local buySuccess, buyResult = pcall(function()
                    return ReplicatedStorage.Events.Market:InvokeServer({ itemName = itemName })
                end)
                if buySuccess and buyResult == true then
                    Market.UpdateContent(currentCategory)
                    local message =  PopupUi.GenerateItemPurchaseMessage(itemName, info.price, itemConfig)
                    PopupUi.Enqueue(itemName, message, 1)
                else
                    -- Optionally show error to user
                end
            end)
        end)
    end
end

-- Module Functions
function Market.Open()
    MarketFrame.Visible = true
    InsightFrame.Close()
end

function Market.Close()
    MarketFrame.Visible = false
    InsightFrame.Close()
end


function Market.Setup()
    MarketFrame.Visible = false

    -- Build selector functions for each category
    local selectorFunctions = {}
    local categories = {}
    for _, button in CategorySelectorsFrame:GetChildren() do
        if not Ui.IsButton(button) then
            continue
        end

        local category = button.Name
        table.insert(categories, category)
        selectorFunctions[category] = function()
            currentCategory = category
            Market.UpdateContent(category)
        end
    end

    -- Create selectors class instance
    local Selectors = SelectorsClass.new(CategorySelectorsFrame, categories, selectorFunctions)
    Selectors:switch("Dropper")

    task.spawn(function()
        -- Ensure leveling data is synched before updating content
        if not ClientPlayerData.DataSynched then
            ClientPlayerData.DataSynchedEvent:Wait()
        end

        Market.UpdateContent(currentCategory)
        ClientPlayerData.LevelUpdate:Connect(function(_)
            Market.UpdateContent(currentCategory)
        end)
    end)
end

return Market