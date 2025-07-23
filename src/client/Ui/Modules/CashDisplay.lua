local CashDisplay = {}
CashDisplay.__index = CashDisplay

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local AssetsDealer = require(Shared.AssetsDealer)
local CashUtility = require(Shared.Utility.CashUtility)

local DEFAULT_UI_SIZE = UDim2.new(2,5,1,5)

function CashDisplay.new(parentInstance)
	local display = setmetatable({}, CashDisplay)

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
		local fadeInfo = TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

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

function CashDisplay:destroy()
	if self.ui then
		self.ui:Destroy()
	end
	if self.attachment then
		self.attachment:Destroy()
	end
end

return CashDisplay
