local Storage = {}

Storage.Dependencies = {
	"Menu",
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- TODO: this module is so ass please use fusion

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local ViewportUtil = require(script.Parent.Util.Viewport)
local SelectorsClass = require(script.Parent.Util.SelectorsClass)

-- Ui Elements
local Gui = Ui.StorageGui
local MainFrame = Gui:WaitForChild("MainFrame")
local InnerFrame = MainFrame:WaitForChild("InnerFrame")
local ItemsFrame = InnerFrame:WaitForChild("ItemsFrame")
local TypeSelectorsFrame = MainFrame:WaitForChild("TypeSelectors")
local SearchBar = InnerFrame:WaitForChild("SearchBar")
local TextBox = SearchBar:WaitForChild("TextBox")
local SearchIcon = SearchBar:WaitForChild("Icon")
local SearchClearButton = SearchIcon:WaitForChild("Clear")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Modules --
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.ClientPlacement)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)
local Signal = require(ReplicatedStorage.Packages.signal)
local SearchUtility = require(Shared.Utility.SearchUtility)

-- Constants --
local ORIGIN = MainFrame.Position
local TYPE_SELECTIONS = { "All", "Dropper", "Belt", "Upgrader", "Forge", "Decor" }

local POP_TWEENINFO = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)
local TYPE_SELECTORS_ORIGNAL_SIZE = TypeSelectorsFrame:GetChildren()[2].Size

-- Variables --
local ItemTemplate = nil
local TypeSelectors = nil
local CurrentSearchQuery = ""
local trove = require(Packages.trove).new()

Storage.OpenedEvent = Signal.new()
Storage.ClosedEvent = Signal.new()
Storage.ItemSelected = Signal.new()

-- Modules --
local ItemUtility = require(Shared.Items.ItemUtility)
local TipsUtility = require(script.Parent.Util.TipsUtility)

-- Functions
local function tweenPopup(goal)
	local tween = TweenService:Create(MainFrame, Ui.MENU_TWEEN_INFO, { Position = goal })
	tween:Play()
end

local function updateItems()
	Ui.ClearFrame(ItemsFrame)
	trove:Clean()

	-- Collect all items with their display names for search
	local allItems = {}
	local itemConfigs = {}

	for itemName, count in ClientPlayerData.Data.Storage do
		local item = AssetsDealer.GetItem(itemName)
		local config = require(item.config)

		allItems[itemName] = config.DisplayName
		itemConfigs[itemName] = { config = config, count = count }
	end

	-- Get items to display based on search query
	local itemsToShow = {}
	if CurrentSearchQuery ~= "" then
		-- Search across all items regardless of type selector
		local searchItems = {}
		for itemName, displayName in pairs(allItems) do
			table.insert(searchItems, displayName)
		end

		local searchResults = SearchUtility.search(CurrentSearchQuery, searchItems)

		-- Map search results back to item names
		for _, displayName in ipairs(searchResults) do
			for itemName, itemDisplayName in pairs(allItems) do
				if itemDisplayName == displayName then
					itemsToShow[itemName] = true
					break
				end
			end
		end
	else
		-- No search query, show items based on type selector
		for itemName, _ in pairs(allItems) do
			local config = itemConfigs[itemName].config
			local type = config.Type

			if TypeSelectors.currentSelection == "All" or type == TypeSelectors.currentSelection then
				itemsToShow[itemName] = true
			end
		end
	end

	-- Create UI items for filtered results
	for itemName, _ in pairs(itemsToShow) do
		local itemData = itemConfigs[itemName]
		local config = itemData.config
		local count = itemData.count

		-- Ui item.
		local uiItem = ItemTemplate:Clone()
		uiItem.Parent = ItemsFrame
		uiItem.ItemCount.Text = "x" .. count
		uiItem.ItemName.Text = `{config.DisplayName}`
		uiItem.Name = itemName

		local viewport = ViewportUtil.CreateItemViewport(itemName)
		viewport.Parent = uiItem

		-- Tips
		local tips = TipsUtility.GetItemConfigTips(config)
		TipsUtility.UpdateTips(uiItem.Tips, tips, 10)

		trove:Connect(uiItem.MouseButton1Click, function()
			Storage.ItemSelected:Fire(itemName)
			ClientPlacement.StartPlacing(itemName)
		end)
	end
end

-- API

function Storage.WaitForItemInItemsFrame(itemName: string)
	return ItemsFrame:WaitForChild(itemName, 5)
end

-- Module Functions
function Storage.Open()
	Gui.Enabled = true
	MainFrame.Position = ORIGIN + UDim2.fromScale(0.5, 0)
	tweenPopup(ORIGIN)

	-- Reset search state
	TextBox.Text = ""
	CurrentSearchQuery = ""
	SearchClearButton.Visible = false
	SearchIcon.ImageTransparency = 0.5

	updateItems()
	TypeSelectors:switch("All")

	Storage.OpenedEvent:Fire()
end

function Storage.Close()
	MainFrame.Position = ORIGIN
	tweenPopup(ORIGIN + UDim2.fromScale(0.5, 0))
	task.wait(Ui.MENU_TWEEN_INFO.Time)
	Gui.Enabled = false

	Storage.ClosedEvent:Fire()
end

function Storage.Setup()
	Gui.Enabled = false
	ItemTemplate = ItemsFrame:WaitForChild("ItemTemplate"):Clone()
	ItemsFrame.ItemTemplate:Destroy()

	-- Create type selectors with callback functions
	local typeSelectorSections = {}
	for _, typeName in TYPE_SELECTIONS do
		typeSelectorSections[typeName] = function()
			updateItems()
		end
	end

	TypeSelectors = SelectorsClass.new(
		TypeSelectorsFrame,
		TYPE_SELECTIONS,
		typeSelectorSections,
		Ui.BUTTON_SELECTED_COLOR,
		Ui.BUTTON_UNSELECTED_COLOR
	)

	-- Search functionality
	TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		CurrentSearchQuery = TextBox.Text
		SearchClearButton.Visible = CurrentSearchQuery ~= ""
		SearchIcon.ImageTransparency = CurrentSearchQuery ~= "" and 1 or 0.5
		updateItems()
	end)

	-- Clear button functionality
	SearchClearButton.MouseButton1Click:Connect(function()
		Ui.PlaySound("Click")
		TextBox.Text = ""
		CurrentSearchQuery = ""
		SearchClearButton.Visible = false
		SearchIcon.ImageTransparency = 0.5
		updateItems()
	end)

	-- Initialize clear button visibility
	SearchClearButton.Visible = false

	ClientPlayerData.StorageUpdate:Connect(function()
		updateItems()
	end)
end

return Storage
