local CashDisplay = {}
CashDisplay.__index = CashDisplay

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local AssetsDealer = require(Shared.AssetsDealer)
local CashUtility = require(Shared.Utility.CashUtility)

local LocalPlayer = Players.LocalPlayer
local DEFAULT_UI_SIZE = UDim2.new(2, 5, 1, 5)
local PROXIMITY_DISTANCE = 20 -- Distance in studs to show the UI

function CashDisplay.new(parentInstance)
	local display = setmetatable({}, CashDisplay)

	-- Store reference to parent instance for proximity checks
	display.parentInstance = parentInstance

	-- Create the cash display UI
	display.ui = AssetsDealer.GetUi("Misc/CashDisplay")
	display.label = display.ui:WaitForChild("Label")
	display.arrow = display.ui:WaitForChild("Frame"):WaitForChild("Arrow")

	-- Create attachment for positioning
	display.attachment = Instance.new("Attachment")
	display.attachment.Position = Vector3.new(0, parentInstance.Size.Y / 2, 0)
	display.attachment.Parent = parentInstance

	-- Parent the UI to the attachment
	display.ui.Parent = display.attachment

	-- Start proximity checking
	display:startProximityCheck()

	return display
end

function CashDisplay:updateValue(value, animate)
	if self.ui and self.label then
		self.label.Text = CashUtility.Format(value)

		-- Optional animation when value changes
		if animate then
			self:pulseEffect()
		end
	end
end

function CashDisplay:pulseEffect()
	if not self.ui then
		return
	end

	local pulseInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)
	local pulseTween = TweenService:Create(self.ui, pulseInfo, {
		Size = DEFAULT_UI_SIZE + UDim2.fromOffset(10, 10),
	})

	pulseTween:Play()
end

function CashDisplay:fade()
	if self.ui and self.label then
		-- Fade out the cash display with transparency and scale
		local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		-- Fade transparency
		local transparencyTween1 = TweenService:Create(self.label, fadeInfo, {
			TextTransparency = 1,
		})

		local transparencyTween2 = TweenService:Create(self.arrow, fadeInfo, {
			ImageTransparency = 1,
		})

		-- Scale down
		local scaleTween = TweenService:Create(self.ui, fadeInfo, {
			Size = DEFAULT_UI_SIZE - UDim2.fromOffset(15, 15),
		})

		transparencyTween1:Play()
		transparencyTween2:Play()
		scaleTween:Play()
	end
end

function CashDisplay:startProximityCheck()
	-- Initially hide the UI
	self.ui.Enabled = false

	-- Connect to RenderStepped for proximity checking
	self.proximityConnection = RunService.RenderStepped:Connect(function()
		self:checkProximity()
	end)
end

function CashDisplay:checkProximity()
	local camera = workspace.CurrentCamera
	if not camera then
		self.ui.Enabled = false
		return
	end

	if not self.parentInstance or not self.parentInstance.Parent then
		self.ui.Enabled = false
		return
	end

	local cameraPosition = camera.CFrame.Position
	local parentPosition = self.parentInstance.Position

	local distance = (cameraPosition - parentPosition).Magnitude

	-- Show UI if within proximity distance, hide if not
	local shouldShow = distance <= PROXIMITY_DISTANCE

	if self.ui.Enabled ~= shouldShow then
		self.ui.Enabled = shouldShow
	end
end

function CashDisplay:destroy()
	-- Disconnect proximity checking
	if self.proximityConnection then
		self.proximityConnection:Disconnect()
		self.proximityConnection = nil
	end

	if self.ui then
		self.ui:Destroy()
	end
	if self.attachment then
		self.attachment:Destroy()
	end
end

return CashDisplay
