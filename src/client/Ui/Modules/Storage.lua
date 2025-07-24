local Storage = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local ViewportUtil = require(script.Parent.Util.Viewport)

-- Ui Elements
local Gui = Ui.StorageGui
local MainFrame = Gui:WaitForChild("MainFrame")
local ItemsFrame = MainFrame:WaitForChild("ItemsFrame")
local TypeSelectorsFrame = MainFrame:WaitForChild("TypeSelectors")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Modules --
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.ClientPlacement)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)

-- Constants --
local ORIGIN = MainFrame.Position
local TYPE_SELECTORS = {
	TypeSelectorsFrame:WaitForChild("Dropper");
	TypeSelectorsFrame:WaitForChild("Belt");
	TypeSelectorsFrame:WaitForChild("Upgrader");
	TypeSelectorsFrame:WaitForChild("Forge");
	TypeSelectorsFrame:WaitForChild("Decor");
}

local POP_TWEENINFO = TweenInfo.new(.15,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,true)
local TYPE_SELECTORS_ORIGNAL_SIZE = TypeSelectorsFrame:GetChildren()[2].Size

-- Variables --
local ItemTemplate = nil
local CurrentType = "Dropper"
local trove = require(Packages.trove).new()

-- Modules --
local ItemUtility = require(Shared.Items.ItemUtility)
local TipsUtility = require(script.Parent.Util.TipsUtility)

-- Functions
local function tweenPopup(goal)
    local tween = TweenService:Create(MainFrame,Ui.MENU_TWEEN_INFO,{Position = goal})
    tween:Play()
end
local function tweenTypeSelector(button,isSelected)
    local goal = isSelected and Ui.BUTTON_SELECTED_COLOR or Ui.BUTTON_UNSELECTED_COLOR
    local colorTween = TweenService:Create(button,Ui.MENU_TWEEN_INFO,{ImageColor3 = goal})
    colorTween:Play()
    -- if isSelected then
    --     local popTween = TweenService:Create(button,POP_TWEENINFO,{Size = TYPE_SELECTORS_ORIGNAL_SIZE + UDim2.fromOffset(4,4)})
    --     popTween:Play()
    -- end
end

local function updateItems()
    Ui.ClearFrame(ItemsFrame)
    trove:Clean()
    for itemName,count in pairs(ClientPlayerData.Data.Storage) do
        -- Item.
        local item = AssetsDealer.GetItem(itemName)

        local config = require(item.config)
        local type = config.Type
        if type ~= CurrentType then continue end
        -- Ui item.
        local uiItem = ItemTemplate:Clone()
        uiItem.Parent = ItemsFrame
        uiItem.ItemCount.Text = "x"..count
		uiItem.ItemName.Text = `{config.DisplayName}`

        local viewport = ViewportUtil.CreateItemViewport(itemName)
        viewport.Parent = uiItem

        -- Tips
        local tips = TipsUtility.GetItemConfigTips(config)
        TipsUtility.UpdateTips(uiItem.Tips,tips,10)

        trove:Connect(uiItem.MouseButton1Click,function()
            ClientPlacement.StartPlacing(itemName)
        end)
    end
end
local function updateTypeSelectors()
    for _,typeSelector in pairs(TYPE_SELECTORS) do
        local isSelectedType = typeSelector.Name == CurrentType
        tweenTypeSelector(typeSelector,isSelectedType)
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
    task.wait(Ui.MENU_TWEEN_INFO.Time)
    Gui.Enabled = false
end

function Storage.Setup()
    Gui.Enabled = false
	ItemTemplate = ItemsFrame:WaitForChild("ItemTemplate"):Clone()
    ItemsFrame.ItemTemplate:Destroy()

    for _,typeSelector in pairs(TYPE_SELECTORS) do
		typeSelector.MouseButton1Click:Connect(function()
			Ui.PlaySound("Click")
            CurrentType = typeSelector.Name
            updateTypeSelectors()
            updateItems()
        end)
    end

    ClientPlayerData.StorageUpdate:Connect(function()
        updateItems()
    end)
end

return Storage