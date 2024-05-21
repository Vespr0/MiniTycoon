local Cash = {}

-- Services --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- LocalPlayer --
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Gui elements --
local Gui = PlayerGui:WaitForChild("Cash")
local MainFrame = Gui:WaitForChild("MainFrame")
local MoneyLabel = MainFrame:WaitForChild("MoneyLabel")

-- Constants --
local TWEEN_INFO = TweenInfo.new(.15,Enum.EasingStyle.Bounce,Enum.EasingDirection.InOut,0,true)
local HOVER_INCREMENT = UDim2.fromOffset(0,3)

-- Modules --
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)

-- Functions --
local function tweenBounce()
    local tween = TweenService:Create(MoneyLabel,TWEEN_INFO,{Position = MoneyLabel.Position+HOVER_INCREMENT})
    tween:Play()
end
local function formatCash(value)
    local chars = string.split(tostring(value), "")
    local string = ""
    for i,c in pairs(chars) do
        if i % 3 == 0 and i ~= #chars then
            string ..= "."
            continue    
        end
        string ..= chars[i]
    end
    return "$"..string
end
local function update(value)
    tweenBounce()
    MoneyLabel.Text = formatCash(value)
end

function Cash.Setup()
    -- Setup label --
    update(ClientPlayerData.GetKey("Cash"))
    ClientPlayerData.CashUpdate:Connect(function(value)
        update(value)
    end)
end

return Cash