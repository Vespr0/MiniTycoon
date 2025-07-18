local Cash = {}

-- Services --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- LocalPlayer --
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Gui elements --
local Gui = PlayerGui:WaitForChild("Cash")
local MainFrame = Gui:WaitForChild("MainFrame")
local MoneyLabel = MainFrame:WaitForChild("MoneyLabel")

-- Constants --
local TWEEN_INFO = TweenInfo.new(.15,Enum.EasingStyle.Bounce,Enum.EasingDirection.InOut,0,true)
local HOVER_INCREMENT = UDim2.fromOffset(0,2)

-- Modules --
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)
local CashUtility = require(Shared.Utility.CashUtility)

-- Functions --
local function tweenBounce()
    local tween = TweenService:Create(MoneyLabel,TWEEN_INFO,{Position = MoneyLabel.Position+HOVER_INCREMENT})
    tween:Play()
end

local function update(value)
    tweenBounce()
    MoneyLabel.Text = CashUtility.Format(value,{
        fullNumber = true,
        decimals = 2
    })
end

function Cash.Setup()
    -- Setup label --
    update(ClientPlayerData.Data.Cash)
    ClientPlayerData.CashUpdate:Connect(function(value)
        update(value)
    end)
end

return Cash