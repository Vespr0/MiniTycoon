local Box = {}
Box.__index = Box

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared

-- Modules
local AssetsDealer = require(Shared.AssetsDealer)
local Ui = require(script.Parent.Parent.Parent.UiUtility)
local SpringModule = require(Shared.Utility.Spring)
local SoundManager = require(Shared.Sound.SoundManager)

-- Constants
local SHAKE_ANGLE = (math.pi/10)
local POP_TWEENINFO = TweenInfo.new(.6,Enum.EasingStyle.Sine)
local VIEWPORT_COLOR = Color3.fromRGB(217, 217, 217)
local CLOSED_LID_ANGLE = math.rad(170)

function Box:popItem()
    if self.item then self.item:Destroy() end
    self.item = self.ui.itemPreview:Clone()
    self.item.Parent = self.ui.MainFrame
    self.item.Position = UDim2.fromScale(0.5, 0.6)
    self.item.Size = UDim2.fromScale(0.15, 0.15)
    self.ui.Starburst.Size = UDim2.fromScale(0.01, 0.01)
    -- Tween
    local tween = TweenService:Create(self.item, POP_TWEENINFO, {Size = UDim2.fromScale(0.3, 0.3)})
    tween:Play()
end

function Box:popStarburst()
    self.ui.Starburst.Visible = true
    local tween = TweenService:Create(self.ui.Starburst, POP_TWEENINFO, {Size = UDim2.fromScale(0.6, 0.6)})
    tween:Play()
end

function Box:popBox()
    self.spring:SetGoal(1)
    self.looseSpring:SetGoal(1)
    self.spring:SetVelocity(self.spring.Velocity + 3)
    self.looseSpring:SetVelocity(3)
end

function Box:pop()
    if not self.opened then self:open() end
    self:popBox()
    self:popStarburst()
    self:popItem()

    SoundManager.PlaySound("Lootboxes/Open",workspace)
end

function Box:setLidAngle(angle)
    self.lid:PivotTo(self.lPivot * CFrame.Angles(0, 0, angle))
end

function Box:updateShake()
    local offset = self.spring.Offset - 1/2
    local lidOffset = self.spring.Offset * 5
    -- Root
    if self.root then
        self.root.CFrame = self.rOriginalCFrame * CFrame.Angles(0, 0, SHAKE_ANGLE * offset)
        self.root.Size = self.rOriginalSize + Vector3.one/4*offset
    end
    -- Lid
    if self.lid then
        self:setLidAngle(SHAKE_ANGLE * lidOffset)
        self.lid.Size = self.lOriginalSize + Vector3.one/2*offset
    end
end

function Box:updateStarburst()
    self.ui.Starburst.Rotation += self.spring.Offset * 2
end

function Box:updateItem()
    if self.item then
        self.item.Rotation = self.looseSpring.Offset * 10
        self.item.Position = UDim2.fromScale(0.5, 0.4*self.looseSpring.Offset - 0.1)
    end
end

function Box:updateGlow(deltaTime)
    local a = math.sin((self.ticks/10))/4 + 3/4
    local colorRange = math.min(255,255*a)
    local color = Color3.fromRGB(colorRange,colorRange,colorRange)

    self.ui.BackViewport.ImageColor3 = color
    self.ui.FrontViewport.ImageColor3 = color
end

function Box:open()
    self.opened = true

    self.ui.FrontViewport.ImageColor3 = VIEWPORT_COLOR
    self.ui.BackViewport.ImageColor3 = VIEWPORT_COLOR
end

function Box.new(name: string,items,ui)
    local box = setmetatable({}, Box)

    box.lootbox = AssetsDealer.GetLootbox(name)
    box.config = require(box.lootbox.config)

    box.ui = ui
    -- Model
    box.rootModel = box.lootbox.Model:Clone()
    box.rootModel.PrimaryPart.Lid.Transparency = 1
    box.rootModel.Parent = ui.FrontViewport
    box.lidModel = box.lootbox.Model:Clone()
    box.lidModel.PrimaryPart.Transparency = 1
    box.lidModel.Parent = ui.BackViewport

    box.root = box.rootModel.PrimaryPart
    box.lid = box.lidModel.PrimaryPart.Lid

    -- Springs
    box.spring = SpringModule.new(1, 6, 60, 0, 0, 0)
    box.looseSpring = SpringModule.new(1, 8, 80, 0, 0, 0)

    -- Camera
    box.currentCamera = Instance.new("Camera")
    box.currentCamera.FieldOfView = 40

    local at = box.root.Position + Vector3.new(-6,1,-6)
    local target = box.root.Position
    box.currentCamera.CFrame = CFrame.lookAt(at, target)
    ui.FrontViewport.CurrentCamera = box.currentCamera
    ui.BackViewport.CurrentCamera = box.currentCamera

    -- Starburst
    ui.Starburst.ImageColor3 = box.config.StarburstColor or ui.Starburst.ImageColor3

    box.spring:SetGoal(0)
    box.spring:SetVelocity(0)
    box.rOriginalCFrame = box.root.CFrame
    box.rOriginalSize = box.root.Size
    box.lOriginalCFrame = box.lid.CFrame
    box.lOriginalSize = box.lid.Size

    box.sORiginalRotation = ui.Starburst.Rotation
    box.sOriginalSize = ui.Starburst.Size

    box.lPivot = box.lid:GetPivot()

    box:setLidAngle(CLOSED_LID_ANGLE)

    box.ticks = 0
    box.currentSpringConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        box.ticks += 1
        if box.opened then
            box:updateShake(box.lid,box.lidModel.PrimaryPart)
            box:updateShake(box.rootModel.PrimaryPart.Lid,box.root)
            box:updateStarburst()
            box:updateItem()

            -- If the spring is still, disconnect the update loop
            if math.abs(box.spring.Offset) < 0.01 and math.abs(box.spring.Velocity) < 0.01 then
                box.currentSpringConnection:Disconnect()
            end
        else
            box:updateGlow(deltaTime)
        end
    end)

    return box
end

return Box
