local Upgrades = {}

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

-- Ui Elements
local MainFrame = Ui.ControlPanelGui:WaitForChild("MainFrame")
local UpgradesFrame = MainFrame:WaitForChild("UpgradesFrame")
local UpgradeTemplate = UpgradesFrame:WaitForChild("Upgrades"):WaitForChild("UpgradeTemplate")
UpgradeTemplate.Parent = script

-- Modules --
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)
local CashUtility = require(Shared.Utility.CashUtility)
local PlotUtility = require(Shared.Plots.PlotUtility)
local Tween = require(script.Parent.Util.Tween)

-- Constants --

-- Variables --
local trove = require(Packages.trove).new()

-- Module Functions
function Upgrades.Open()
    UpgradesFrame.Visible = true
end

function Upgrades.Close()
    UpgradesFrame.Visible = false
end

function Upgrades.Connect(name,info)
	local frame = UpgradeTemplate:Clone()
	frame.Parent = UpgradesFrame:WaitForChild("Upgrades")
	local upperFrame = frame:WaitForChild("UpperFrame")
	local lowerFrame = frame:WaitForChild("LowerFrame")
	local button = upperFrame:WaitForChild("Upgrade") :: ImageButton
	-- Ticks
	local ticks = upperFrame:WaitForChild("Ticks")
	local tickTemplate = ticks.TickTemplate
	tickTemplate.Parent = script
	local maxValue = info.MaxValue
	
	-- Functions
	local function getCurrentValue()
		return ClientPlayerData.Data.Plot[name]
	end
	local function isMaxxed()
		return getCurrentValue() >= maxValue
	end
	local function updateCost()
		upperFrame.Upgrade.Price.Text = "$ "..PlotUtility.UpgradeCosts[name](getCurrentValue())
	end
	local function updateMaxxed()
		button:WaitForChild("Maxxed").Visible = isMaxxed()
		--button.Visible = not isMaxxed()
	end
	local function updateProgress(value)
		for _,frame in ticks:GetChildren() do
			if frame:IsA("Frame") then 
				frame:Destroy()
			end
		end
		ticks:WaitForChild("GridLayout").CellSize = UDim2.fromScale(1/maxValue,1)
		local currentValue = getCurrentValue()
		for i = 1,currentValue do
			local newTick = tickTemplate:Clone()
			newTick.Parent = ticks
			newTick.Visible = true
		end
	end
	local function updateTitle()
		-- Basic info
		upperFrame.UpgradeName.Text = info.DisplayName.." : "..getCurrentValue()
	end
	
	local function update()
		updateCost()
		updateProgress()	
		updateMaxxed()
		updateTitle()
	end

	update()
	
	button.MouseButton1Down:Connect(function()
		if isMaxxed() then return end
		
		-- Animation
		Tween.ButtonPush(button)
		Ui.PlaySound("Upgrade")

		local cash = ClientPlayerData.Data.Cash
		local currentValue = getCurrentValue()
		
		local newValue,message = Events.Upgrade:InvokeServer(name)

		if newValue then
			ClientPlayerData.Data.Plot[name] = newValue
			update()
		else
			warn(message)
		end	
	end)
end

function Upgrades.Setup()    
	for name,info in PlotUtility.Upgrades do
		Upgrades.Connect(name,info)
	end
end

return Upgrades