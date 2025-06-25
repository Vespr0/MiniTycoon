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

function Box:close()
	if self.isClosing then return end
	self.isClosing = true
	self.opened = false

	-- Disconnect existing updates
	if self.currentSpringConnection then
		self.currentSpringConnection:Disconnect()
		self.currentSpringConnection = nil
	end

	-- Calculate current lid angle
	local currentCFrame = self.lid:GetPivot()
	local relativeCF = self.lPivot:ToObjectSpace(currentCFrame)
	local axis, angle = relativeCF.Rotation:ToAxisAngle()
	local currentAngle = axis.Z < 0 and -angle or angle

	-- Animate lid closing
	local angleValue = Instance.new("NumberValue")
	angleValue.Value = currentAngle

	local lidTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local lidTween = TweenService:Create(angleValue, lidTweenInfo, {Value = CLOSED_LID_ANGLE})

	lidTween.Completed:Connect(function()
		angleValue:Destroy()
		-- Animate UI exit
		local exitTween = TweenService:Create(self.ui.MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 1.5, 0)
		})
		exitTween:Play()

		SoundManager.PlaySound("Lootboxes/Close", workspace)

		exitTween.Completed:Connect(function()
			-- Cleanup resources
			if self.rootModel then
				self.rootModel:Destroy()
				self.rootModel = nil
			end
			if self.lidModel then
				self.lidModel:Destroy()
				self.lidModel = nil
			end
			if self.item then
				self.item:Destroy()
				self.item = nil
			end
			self.ui.MainFrame:Destroy()
		end)
	end)

	angleValue.Changed:Connect(function()
		self:setLidAngle(angleValue.Value)
	end)

	lidTween:Play()
end

function Box.new(name: string,items,ui)
    local self = setmetatable({}, Box)

    self.lootbox = AssetsDealer.GetLootbox(name)
    self.config = require(self.lootbox.config)

    self.ui = ui
    -- Model
    self.rootModel = self.lootbox.Model:Clone()
    self.rootModel.PrimaryPart.Lid.Transparency = 1
    self.rootModel.Parent = ui.FrontViewport
    self.lidModel = self.lootbox.Model:Clone()
    self.lidModel.PrimaryPart.Transparency = 1
    self.lidModel.Parent = ui.BackViewport

    self.root = self.rootModel.PrimaryPart
    self.lid = self.lidModel.PrimaryPart.Lid

    -- Springs
    self.spring = SpringModule.new(1, 6, 60, 0, 0, 0)
    self.looseSpring = SpringModule.new(1, 8, 80, 0, 0, 0)

    -- Camera
    self.currentCamera = Instance.new("Camera")
    self.currentCamera.FieldOfView = 40

    local at = self.root.Position + Vector3.new(-6,1,-6)
    local target = self.root.Position
    self.currentCamera.CFrame = CFrame.lookAt(at, target)
    ui.FrontViewport.CurrentCamera = self.currentCamera
    ui.BackViewport.CurrentCamera = self.currentCamera

    -- Starburst
    ui.Starburst.ImageColor3 = self.config.StarburstColor or ui.Starburst.ImageColor3

    self.spring:SetGoal(0)
    self.spring:SetVelocity(0)
    self.rOriginalCFrame = self.root.CFrame
    self.rOriginalSize = self.root.Size
    self.lOriginalCFrame = self.lid.CFrame
    self.lOriginalSize = self.lid.Size

    self.sORiginalRotation = ui.Starburst.Rotation
    self.sOriginalSize = ui.Starburst.Size

    self.lPivot = self.lid:GetPivot()

    self:setLidAngle(CLOSED_LID_ANGLE)

    self.ticks = 0
    self.currentSpringConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        self.ticks += 1
        if self.opened then
            self:updateShake()
            self:updateStarburst()
            self:updateItem()

            -- If the spring is still, disconnect the update loop
            if math.abs(self.spring.Offset) < 0.01 and math.abs(self.spring.Velocity) < 0.01 then
                self.currentSpringConnection:Disconnect()
            end
        else
            self:updateGlow(deltaTime)
        end
    end)

    return self
end

return Box
