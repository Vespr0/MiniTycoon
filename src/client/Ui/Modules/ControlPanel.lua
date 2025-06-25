local ControlPanel = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local UpgradesUi = require(script.Parent.Upgrades)

-- Ui Elements 
local Gui = Ui.ControlPanelGui
local MainFrame = Gui:WaitForChild("MainFrame")

-- Modules --
local AssetsDealer = require(Shared.AssetsDealer)
local ItemUtility = require(Shared.Items.ItemUtility)
local Tween = require(script.Parent.Util.Tween)
local SelectorsClass = require(script.Parent.Util.SelectorsClass)

local Selectors = SelectorsClass.new(
	MainFrame,
	{"Upgrades","Settings"},
	{Upgrades = UpgradesUi}
)

-- Variables --
local trove = require(Packages.trove).new()
local CurrentSection

-- Module Functions
function ControlPanel.Open()
	Gui.Enabled = true
	MainFrame.Position = Selectors.origin+UDim2.fromScale(0,1)
	Tween.Popup(MainFrame,Selectors.origin)
end

function ControlPanel.Close()
	MainFrame.Position = Selectors.origin
	Tween.Popup(MainFrame,Selectors.origin+UDim2.fromScale(0,1))
	task.wait(Ui.MENU_TWEEN_INFO.Time)
	Gui.Enabled = false
end

function ControlPanel.Setup()
	Gui.Enabled = false
	MainFrame.Visible = true
	
	warn(`Shop has been setup`)
	Selectors:switch("Upgrades")
end

return ControlPanel