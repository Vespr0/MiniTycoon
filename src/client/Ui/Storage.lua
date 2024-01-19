local Storage = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Gui = PlayerGui:WaitForChild("Storage")
local MainFrame = Gui:WaitForChild("MainFrame")
local ItemsFrame = MainFrame:WaitForChild("ItemsFrame")
local TypeSelectorsFrame = MainFrame:WaitForChild("TypeSelectors")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Modules --
local UiUtility = require(Shared.UiUtility)
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientPlacement = require(Shared.Plots.ClientPlacement)
local ClientPlayerData = require(script.Parent.Parent.Data.ClientPlayerData)

-- Constants --
local TWEEN_INFO = TweenInfo.new(.15,Enum.EasingStyle.Sine)
local ORIGIN = MainFrame.Position
local TYPE_SELECTORS = {
    TypeSelectorsFrame.Dropper;
    TypeSelectorsFrame.Belt;
    TypeSelectorsFrame.Upgrader;
    TypeSelectorsFrame.Forge;
}
local TYPE_UNSELECTED_COLOR = Color3.fromRGB(27, 27, 27)
local TYPE_SELECTED_COLOR = Color3.fromRGB(255, 255, 255)

-- Variables --
local ItemTemplate = nil
local CurrentType = "Dropper"
local trove = require(Packages.trove).new()

-- Modules --
local ItemUtility = require(Shared.Items.ItemUtility)

-- Functions
local function tweenPopup(goal)
    local tween = TweenService:Create(MainFrame,TWEEN_INFO,{Position = goal})
    tween:Play()
end
local function tweenTypeSelector(button,goal)
    local tween = TweenService:Create(button,TWEEN_INFO,{ImageColor3 = goal})
    tween:Play()
end

local function updateItems()
    UiUtility.ClearFrame(ItemsFrame)
    trove:Clean()
    for id,count in pairs(ClientPlayerData.GetKey("Storage")) do
        --print(id.." - x"..count)
        local itemName,itemInfo = ItemUtility.GetItemFromID(id)
        -- Item.
        local item = AssetsDealer.GetItem(itemInfo.Directory)
        local config = require(item.config)
        local type = config.Type
        --print(type.."/"..CurrentType)
        if type ~= CurrentType then continue end
        -- Ui item.
        local uiItem = ItemTemplate:Clone()
        uiItem.Parent = ItemsFrame
        uiItem.ItemCount.Text = "x"..count
        uiItem.ItemName.Text = config.DisplayName
        trove:Connect(uiItem.MouseButton1Click,function()
            ClientPlacement.StartPlacing(itemName)
        end)
    end
end
local function updateTypeSelectors()
    for _,typeSelector in pairs(TYPE_SELECTORS) do
        local isSelectedType = typeSelector.Name == CurrentType
        tweenTypeSelector(typeSelector,isSelectedType and TYPE_SELECTED_COLOR or TYPE_UNSELECTED_COLOR)
    end
end

-- Module Functions
function Storage.Open()
    Gui.Enabled = true
    MainFrame.Position = ORIGIN+UDim2.fromScale(0.5,0)
    tweenPopup(ORIGIN)
    updateItems()
    updateTypeSelectors()
end

function Storage.Close()
    MainFrame.Position = ORIGIN
    tweenPopup(ORIGIN+UDim2.fromScale(0.5,0))
    task.wait(TWEEN_INFO.Time)
    Gui.Enabled = false
end

function Storage.Setup()
    Gui.Enabled = false
    ItemTemplate = ItemsFrame.ItemTemplate:Clone()
    ItemsFrame.ItemTemplate:Destroy()

    for _,typeSelector in pairs(TYPE_SELECTORS) do
        typeSelector.MouseButton1Click:Connect(function()
            CurrentType = typeSelector.Name
            updateTypeSelectors()
            updateItems()
        end)
    end

    ClientPlayerData.DataStorageUpdate:Connect(function()
        updateItems()
    end)
end

return Storage