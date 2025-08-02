local Stocks = {}

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
local StocksFrame = MainFrame:WaitForChild("StocksFrame")
local OresContainer = StocksFrame:WaitForChild("Ores")
local OreTemplate = OresContainer:WaitForChild("OreTemplate")
OreTemplate.Parent = script

-- Modules --
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.Placement.ClientPlacement)
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

-- Module Functions
function Stocks.Open()
	StocksFrame.Visible = true
end

function Stocks.Close()
	StocksFrame.Visible = false
end

function Stocks.Setup()    

end

return Stocks