local LoadingScreen = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local LoadingScreenGui = PlayerGui:WaitForChild("LoadingScreen")
local MainFrame = LoadingScreenGui:WaitForChild("MainFrame")
local ProgressBar = MainFrame:WaitForChild("ContainerBar"):WaitForChild("ProgressBar")
local Context = MainFrame:WaitForChild("Context")

function LoadingScreen.Open()
    LoadingScreenGui.Enabled = true
end

function LoadingScreen.Close()

    -- Fade time
    -- TODO: Fade animation
    task.wait(2)

    LoadingScreenGui.Enabled = false
end

function LoadingScreen.SetProgress(percentage)
    percentage = math.clamp(percentage, 0, 1)
    local tween = TweenService:Create(ProgressBar, TweenInfo.new(.4), { Size = UDim2.fromScale(percentage, 1) })
    tween:Play()
end

function LoadingScreen.SetContext(text)
    Context.Text = text
end

return LoadingScreen