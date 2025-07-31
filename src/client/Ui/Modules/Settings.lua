local Settings = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)

-- Ui Elements
local Gui = Ui.ControlPanelGui
local MainFrame = Gui:WaitForChild("MainFrame")
local SettingsFrame = MainFrame:WaitForChild("SettingsFrame")

-- Modules
local Trove = require(Packages.trove)

-- Variables
local trove = Trove.new()


function Settings.Setup()

    
end

return Settings