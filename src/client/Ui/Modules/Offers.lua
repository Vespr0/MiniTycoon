local Offers = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)

-- Ui Elements
local OffersFrame = Ui.ShopGui:WaitForChild("MainFrame"):WaitForChild("OffersFrame")

-- Modules --
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientPlacement = require(Shared.Plots.ClientPlacement)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)

-- Constants --

-- Variables --
local trove = require(Packages.trove).new()
local CurrentSection

-- Modules --
local ItemUtility = require(Shared.Items.ItemUtility)

-- Module Functions
function Offers.Open()
    OffersFrame.Visible = true
end

function Offers.Close()
    OffersFrame.Visible = false
end

function Offers.Setup()
    OffersFrame.Visible = true
end

return Offers