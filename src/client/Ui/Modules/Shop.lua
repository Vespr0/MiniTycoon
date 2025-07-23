local Shop = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local OffersUi = require(script.Parent.Offers)
local MarketUi = require(script.Parent.Market)

-- Ui Elements 
local Gui = Ui.ShopGui
local MainFrame = Gui:WaitForChild("MainFrame")
local SectionSelectors = MainFrame:WaitForChild("SectionSelectors")

-- Modules --
local AssetsDealer = require(Shared.AssetsDealer)
local ItemUtility = require(Shared.Items.ItemUtility)
local Tween = require(script.Parent.Util.Tween)
local SelectorsClass = require(script.Parent.Util.SelectorsClass)


local origin = MainFrame.Position
local Selectors = SelectorsClass.new(
	SectionSelectors,
	{"Market","Offers","Lootboxes","Stocks"},
	{Market = MarketUi, Offers = OffersUi}
)

-- Variables --
local trove = require(Packages.trove).new()
local CurrentSection

-- Module Functions

Shop.FirstOpen = true

function Shop.Open()
	Gui.Enabled = true
	MainFrame.Position = origin + UDim2.fromScale(0,1)
	Tween.Popup(MainFrame, origin)
	if Shop.FirstOpen then
		Shop.FirstOpen = false
		Selectors:switch("Market")
	end
end


function Shop.Close()
	MainFrame.Position = origin
	Tween.Popup(MainFrame, origin + UDim2.fromScale(0,1))
	task.wait(Ui.MENU_TWEEN_INFO.Time)
	Gui.Enabled = false
end

function Shop.Setup()
	Gui.Enabled = false
	-- task.wait(.1)
	-- Selectors:switch("Market")
end

return Shop