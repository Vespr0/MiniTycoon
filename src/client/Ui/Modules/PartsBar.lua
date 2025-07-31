local PartsBar = {}

-- Services --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)
local UiUtility = require(script.Parent.Parent.UiUtility)

-- Gui elements --
local MainFrame = UiUtility.TopGui:WaitForChild("MainFrame"):WaitForChild("PartsBar")
local Fill = MainFrame:WaitForChild("Fill")
local PartsLabel = MainFrame:WaitForChild("PartsLabel")

-- Constants --
local TWEEN_INFO = TweenInfo.new(.1,Enum.EasingStyle.Linear)

-- Modules --
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)

-- Functions --
local function update(currentPartsCount: number)
    local plotLevel = ClientPlayerData.Data.Plot.PlotLevel
    print(plotLevel)
    local maxParts = PlotUtility.GetMaxPartsFromPlotLevel(plotLevel)
    
    PartsLabel.Text = `PARTS: {currentPartsCount}/{maxParts}`

    local xScale = math.min(math.max(currentPartsCount/maxParts,.04),1)
    local tween = TweenService:Create(Fill,TWEEN_INFO,{Size = UDim2.fromScale(xScale,Fill.Size.Y.Scale)})
    tween:Play()
end

function PartsBar.Setup()
    -- Setup label --

    local plot = nil

    task.spawn(function()
        while not plot do
            plot = PlotUtility.GetPlotFromPlayer(Players.LocalPlayer)
            task.wait(.1)
        end
    end)

    local PartsValue = plot:FindFirstChild("Parts") :: IntValue
    if not PartsValue then 
        warn("PartsValue is missing.")
        return 
    end

    update(PartsValue.Value)

    -- Update when the data is synched too (it's a one time thing)
    ClientPlayerData.DataSynchedEvent:Connect(function()
        update(PartsValue.Value)
    end)
    
    PartsValue.Changed:Connect(function(value)
        update(value)
    end)
end

return PartsBar