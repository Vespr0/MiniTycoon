local Alert = {}
Alert.__index = Alert

local Ui = require(script.Parent.Parent.Parent.UiUtility)
local Fusion = Ui.Fusion
local scoped = Ui.scoped
local TweenService = game:GetService("TweenService")

-- Configuration Constants
local PULSE_ANIMATION_TIME = 1 -- Duration of each pulse animation (seconds)
local PULSE_MAX_THICKNESS = 10 -- Maximum thickness of pulse stroke
local PULSE_START_TRANSPARENCY = 0.3 -- Starting transparency of pulse stroke
local PULSE_END_TRANSPARENCY = 1 -- Ending transparency of pulse stroke (fully transparent)

-- Alert Frame Constants
local ALERT_SIZE = UDim2.new(0.5, -5, 0.5, -5)
local ALERT_POSITION = UDim2.new(1.25, 0, -0.2, 0)
local ALERT_COLOR = Color3.fromRGB(255, 23, 73)
local ALERT_Z_INDEX = 50

-- Pulse Stroke Constants
local PULSE_STROKE_COLOR = Color3.fromRGB(255, 150, 170)

-- Animation Constants
local PULSE_TWEEN_INFO = TweenInfo.new(PULSE_ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Alert.new()
	local self = setmetatable({}, Alert)
	self.isVisible = false
	self.scope = scoped(Fusion)
	self.pulseConnection = nil
	self.pulseTween = nil
	self.pulseStroke = nil
	return self
end

function Alert:setup()
	-- Create the pulse stroke that will be animated
	self.pulseStroke = self.scope:New("UIStroke")({
		Color = PULSE_STROKE_COLOR,
		Thickness = 0,
		Transparency = PULSE_END_TRANSPARENCY,
	})

	-- Create the main frame using Fusion
	self.frame = self.scope:New("Frame")({
		Size = ALERT_SIZE,
		Position = ALERT_POSITION,
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = ALERT_COLOR,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = ALERT_Z_INDEX,

		[Fusion.Children] = {
			-- UI corner for circular shape
			self.scope:New("UICorner")({
				CornerRadius = UDim.new(0.5, 0),
			}),

			-- Pulse stroke
			self.pulseStroke,
		},
	})

	return self.frame
end

function Alert:show(parent)
	if not self.frame then
		self:setup()
	end

	if parent then
		self.frame.Parent = parent
	end

	self.frame.Visible = true
	self.isVisible = true

	-- Start automatic pulsing
	self:startAutoPulse()
end

function Alert:hide()
	if self.frame then
		self.frame.Visible = false
		self.isVisible = false
	end

	-- Stop automatic pulsing
	self:stopAutoPulse()
end

function Alert:destroy()
	-- Stop automatic pulsing
	self:stopAutoPulse()

	-- Clean up tween
	if self.pulseTween then
		self.pulseTween:Cancel()
		self.pulseTween = nil
	end

	if self.scope then
		self.scope:doCleanup()
		self.scope = nil
	end

	self.frame = nil
	self.pulseStroke = nil
	self.isVisible = false
end

function Alert:pulse()
	if not self.isVisible or not self.pulseStroke then
		return
	end

	-- Cancel any existing tween
	if self.pulseTween then
		self.pulseTween:Cancel()
	end

	-- Reset stroke to starting state
	self.pulseStroke.Thickness = 0
	self.pulseStroke.Transparency = PULSE_START_TRANSPARENCY

	-- Create and start the pulse tween
	self.pulseTween = TweenService:Create(self.pulseStroke, PULSE_TWEEN_INFO, {
		Thickness = PULSE_MAX_THICKNESS,
		Transparency = PULSE_END_TRANSPARENCY,
	})

	self.pulseTween:Play()
end

function Alert:startAutoPulse()
	-- Stop any existing pulse
	self:stopAutoPulse()

	-- Start pulsing at configured interval
	self.pulseConnection = task.spawn(function()
		while self.isVisible do
			self:pulse()
			task.wait(PULSE_ANIMATION_TIME)
		end
	end)
end

function Alert:stopAutoPulse()
	if self.pulseConnection then
		task.cancel(self.pulseConnection)
		self.pulseConnection = nil
	end

	-- Also cancel any active tween
	if self.pulseTween then
		self.pulseTween:Cancel()
		self.pulseTween = nil
	end
end

return Alert
