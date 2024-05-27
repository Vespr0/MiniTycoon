local Unboxing = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local AssetsDealer = require(Shared.AssetsDealer)

-- Modules
local Ui = require(script.Parent.Parent.UiUtility)
local SpringModule = require(Shared.Utility.Spring)

-- Ui Elements 
local Gui = Ui.UnboxingGui
local MainFrame = Gui:WaitForChild("MainFrame") :: Frame
local BoxViewport = MainFrame:WaitForChild("BoxViewport") :: ViewportFrame
local Starburst = MainFrame:WaitForChild("Starburst") :: ImageLabel
local itemPreview = MainFrame:WaitForChild("ItemPreview") :: ImageLabel
itemPreview.Parent = script

-- Variables
local currentSpringConnection 
local rOriginalCFrame,rOriginalSize
local lPivot,lOriginalCFrame,lOriginalSize
local sORiginalRotation,sOriginalSize 
local spring = SpringModule.new(1, 6, 60, 0, 0, 0)

-- Constants
local SHAKE_ANGLE = (math.pi/10)

function shakeBox(model)
    spring:SetGoal(1)
    spring:SetVelocity(spring.Velocity + 3)
end

local function updateShake(lid,root)
    local offset = spring.Offset - 1/2
    local lidOffset = spring.Offset * 5
    local starOffset = lidOffset * 5
    -- Root
    root.CFrame = rOriginalCFrame * CFrame.Angles(0, 0, SHAKE_ANGLE * offset)
    root.Size = rOriginalSize + Vector3.one/4*offset
    -- Lid
    lid:PivotTo(lPivot * CFrame.Angles(0, 0, SHAKE_ANGLE * lidOffset))
    lid.Size = lOriginalSize + Vector3.one/4*offset

    Starburst.Rotation += 1
    Starburst.Size = sOriginalSize + UDim2.fromOffset(starOffset, starOffset)
end

function Unboxing.OpenLootbox(name)
    local lootbox = AssetsDealer.GetLootbox(name)

    local config = require(lootbox.config)

    local model = lootbox.Model:Clone()
    local primaryPart = model.PrimaryPart
    model.Parent = BoxViewport
    local camera = Instance.new("Camera")
    camera.FieldOfView = 40

    local at = primaryPart.Position + Vector3.new(-6,2,-6)
    local target = primaryPart.Position
    camera.CFrame = CFrame.lookAt(at, target)
    BoxViewport.CurrentCamera = camera

    local root = model:WaitForChild("Root")
    local lid = root:WaitForChild("Lid")

    Starburst.ImageColor3 = config.StarburstColor or Starburst.ImageColor3

    spring:SetGoal(0)
    spring:SetVelocity(0)
    rOriginalCFrame = root.CFrame
    rOriginalSize = root.Size
    lOriginalCFrame = lid.CFrame
    lOriginalSize = lid.Size

    sORiginalRotation = Starburst.Rotation
    sOriginalSize = Starburst.Size

    lPivot = lid:GetPivot()
    
    currentSpringConnection = game:GetService("RunService").Heartbeat:Connect(function()
        updateShake(lid,root)

        -- If the spring is still, disconnect the update loop
        if math.abs(spring.Offset) < 0.01 and math.abs(spring.Velocity) < 0.01 then
            currentSpringConnection:Disconnect()
        end
    end)

    task.spawn(function()
        while true do
            shakeBox(model)
            task.wait(2)
        end
    end)
end

function Unboxing.Setup()
    Unboxing.OpenLootbox("RookieBox")
end

return Unboxing