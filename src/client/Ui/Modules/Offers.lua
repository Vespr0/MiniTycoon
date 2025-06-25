local Offers = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
local Events = ReplicatedStorage.Events

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local Time = require(Shared.Utility.Time)
local ViewportUtil = require(script.Parent.Util.Viewport)

-- Ui Elements
local MainFrame = Ui.ShopGui:WaitForChild("MainFrame")
local OffersFrame = MainFrame:WaitForChild("OffersFrame")
local OffersContainer = OffersFrame:WaitForChild("OffersContainer")
local ItemTemplate = OffersContainer:WaitForChild("ItemTemplate")
local InsightFrame = MainFrame:WaitForChild("InsightFrame")
local Preview = InsightFrame:WaitForChild("Preview")
local ViewportGradient = OffersFrame:WaitForChild("ViewportGradient")
ViewportGradient.Parent = script
Preview.Parent = script
ItemTemplate.Parent = script
local Timer = OffersFrame:WaitForChild("Timer")

-- Modules --
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.ClientPlacement)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)
local ItemUtility = require(Shared.Items.ItemUtility)
local DataUtility = require(Shared.Data.DataUtility)
local CashUtility = require(Shared.Utility.CashUtility)
local Tween = require(script.Parent.Util.Tween)
local Colors = require(script.Parent.Util.Colors)
local Trove = require(Packages.trove)

-- Constants --

-- Variables --
local trove = require(Packages.trove).new()
local currentExpiration 
local currentOffers
local currentViewports = {}

-- Local Functions
function get()
    local data = Events.Offers:InvokeServer("Get")

    currentExpiration = data.expiration
    currentOffers = data.offers
end

local currentInsightTrove = nil

local function canAfford(price)
	return ClientPlayerData.Data.Cash >= price
end

local function closeInsight()
    local preview = InsightFrame:FindFirstChild("Preview")
    if preview then preview:Destroy() end
    InsightFrame.Title.Text = "(Select an offer)"
    InsightFrame.Description.Text = ""
    InsightFrame.Rarity.Text = ""
    InsightFrame.Buy.Price.Text = ""
	InsightFrame.Buy.Visible = false
	
	-- Destroy trove if it exists
	if currentInsightTrove then currentInsightTrove:Destroy() end
end

local function buyOffer(offerID,price,itemName)
	Ui.PlaySound("Purchase")
	
    local success,error = Events.Offers:InvokeServer("Buy",{offerID = offerID})
    if not success then warn(error) return end
	
    ClientPlayerData.Read({
		type = "SingleOffer";
        arg1 = offerID;
        arg2 = {
            ItemName = itemName;
            Price = price;
            Bought = true;
        };
    })

    OffersContainer[offerID].Sold.Visible = true
	closeInsight()	
end

local function insight(itemName, name, config, price, offerID, rarityInfo)
	-- Destroy trove if it exists
	if currentInsightTrove then currentInsightTrove:Destroy() end
	
    if InsightFrame:FindFirstChild("Preview") then
        InsightFrame.Preview:Destroy()
    end
    InsightFrame.Title.Text = config.DisplayName
    InsightFrame.Description.Text = config.Description or '<font transparency="0.5"> This item has no description. </font>'
    local rarity = config.Rarity or "Common"
    InsightFrame.Rarity.Text = string.upper(rarity)
    InsightFrame.Rarity.TextColor3 = rarityInfo.Color
    InsightFrame.Rarity.UIStroke.Color = rarityInfo.StrokeColor

    local insightViewport = ViewportUtil.GenerateItemViewport(name,Preview)
    insightViewport.Name = "Preview"
    insightViewport.Parent = InsightFrame
    -- Price 
    InsightFrame.Buy.Price.Text = CashUtility.Format(price,{
        fullNumber = false,
        decimals = 0
    })
    -- Buy
	InsightFrame.Buy.Visible = true
	
	local buyButton = InsightFrame.Buy
	
	currentInsightTrove = Trove.new()
	
	currentInsightTrove:Add(RunService.RenderStepped:Connect(function()
		InsightFrame.Buy.FakeButton.BackgroundColor3 = canAfford(price) and Colors.Buttons.Green or Colors.Buttons.Red
	end))
	
	currentInsightTrove:Add(buyButton.MouseButton1Click:Connect(function()
		if canAfford(price) then
			Tween.ButtonPush(buyButton)
			buyOffer(offerID,price,itemName)
		else
			Ui.PlaySound("Error")
		end
    end))
end 

local function checkExpiration()
    local diff = os.difftime(currentExpiration,workspace:GetServerTimeNow())
    return diff <= 0,diff
end

local function updateContainer()
    if checkExpiration() then return end -- Shoudln't be expired.

    for _,offer in pairs(OffersContainer:GetChildren()) do
        if offer:IsA("TextButton") then
            offer:Destroy()
        end
    end
    currentViewports = {} -- TODO: is this a memory leak? 

    if not currentOffers or not next(currentOffers) then return end 

    for offerID,offer in pairs(currentOffers) do
        local itemName = offer.ItemName
        local price = offer.Price
        local bought = offer.Bought

        local config = ItemUtility.GetItemConfig(itemName)

        if not itemName then warn("Item with ID "..itemName.." does not exist, can't show offer.") continue end

        local item = ItemTemplate:Clone()
        item.Name = offerID
        item.Parent = OffersContainer

        -- ItemName
        local itemNameLabel = item:WaitForChild("ItemName")
        local rarity = config.Rarity or "Common"
        local rarityInfo = ItemInfo.Rarities[rarity]
        itemNameLabel.Text = config.DisplayName     
        itemNameLabel.TextColor3 = rarityInfo.Color
        itemNameLabel.UIStroke.Color = rarityInfo.StrokeColor
        
        -- Bought
        item.Sold.Visible = bought

        -- Price 
        item:WaitForChild("Price").Text = CashUtility.Format(price,{
            fullNumber = false,
            decimals = 0
        })

        local viewport = ViewportUtil.GenerateItemViewport(itemName)
        viewport.Parent = item
        viewport.ZIndex = 3

        table.insert(currentViewports,viewport)

        local gradient = ViewportGradient:Clone()
        gradient.Parent = viewport

        item.MouseButton1Click:Connect(function()
            insight(itemName, itemName, config, price, offerID, rarityInfo)
        end)
    end
end

function Offers.Reload()
    get()
    local expired = checkExpiration()
    if not expired then
        updateContainer()
    end
end

local function spin()
    local preview = InsightFrame:FindFirstChild("Preview")
    if not preview then return end

    local model = preview:FindFirstChildWhichIsA("Model")
    if model then
        model:PivotTo(model:GetPivot()*CFrame.Angles(0,math.rad(0.3),0))
    end
end

local function update()
    local expired,diff = checkExpiration()
    MainFrame:WaitForChild("Shadow").Visible = expired
    Timer.Text = "Offers reset in: "..Time.GetFullTimeString(diff)

    -- Spin
    spin()
end

-- Module Functions
function Offers.Open()
    OffersFrame.Visible = true
end

function Offers.Close()
    OffersFrame.Visible = false
end

function Offers.Setup()    
    Offers.Reload()
    closeInsight()
    local paused = false
    RunService.RenderStepped:Connect(function()
        if checkExpiration() then
            if paused then return end
            paused = true
            Offers.Reload()
            paused = false
        end
        update()
    end)
end

return Offers