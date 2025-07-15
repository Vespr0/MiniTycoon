local LevelBar = {}

-- Services --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local LevelingUtil = require(Shared.Data.LevelingUtil)

-- LocalPlayer --
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Gui elements --
local Gui = PlayerGui:WaitForChild("LevelBar")
local MainFrame = Gui:WaitForChild("MainFrame")
local Fill = MainFrame:WaitForChild("Fill")
local LevelLabel = MainFrame:WaitForChild("LevelLabel")

-- Constants --
local TWEEN_INFO = TweenInfo.new(.1,Enum.EasingStyle.Linear)

-- Modules --
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)

-- Functions --
local function update(exp: number,level: number)
    local maxExp = LevelingUtil.GetExpForLevel(level+1)
    
    LevelLabel.Text = "LEVEL: "..tostring(level)

    local xScale = math.min(math.max(exp/maxExp,.04),1)
    local tween = TweenService:Create(Fill,TWEEN_INFO,{Size = UDim2.fromScale(xScale,Fill.Size.Y.Scale)})
    tween:Play()
end

function LevelBar.Setup()
    -- Setup label --
	update(ClientPlayerData.Data.Cash,ClientPlayerData.Data.Level)
    ClientPlayerData.ExpUpdate:Connect(function(exp: number,level: number)
        update(exp,level)
    end)
end

return LevelBar