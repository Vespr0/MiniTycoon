local Index = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)

-- Ui Elements 
local Gui = Ui.IndexGui
local MainFrame = Gui:WaitForChild("MainFrame")

-- Variables --
local ORIGIN = MainFrame.Position

-- Module Functions
function Index.Open()
    Gui.Enabled = true
    MainFrame.Position = ORIGIN + UDim2.fromScale(0.5, 0)
    local tween = TweenService:Create(MainFrame, Ui.MENU_TWEEN_INFO, {Position = ORIGIN})
    tween:Play()
end

function Index.Close()
    MainFrame.Position = ORIGIN
    local tween = TweenService:Create(MainFrame, Ui.MENU_TWEEN_INFO, {Position = ORIGIN + UDim2.fromScale(0.5, 0)})
    tween:Play()
    task.wait(Ui.MENU_TWEEN_INFO.Time)
    Gui.Enabled = false
end

function Index.Setup()
    Gui.Enabled = false
    MainFrame.Visible = true
end

return Index
