local ButtonUtility = {}

-- Services
local TweenService = game:GetService("TweenService")

-- Modules
local Colors = require(script.Parent.Colors)
local Ui = require(script.Parent.Parent.Parent.UiUtility)

-- Constants
ButtonUtility.HOVER_TWEEN_INFO = TweenInfo.new(.2,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,false)
ButtonUtility.BOUNCY_BUTTON_TWEEN_INFO = TweenInfo.new(.1,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,0,true)
ButtonUtility.BUTTON_OFFSET = -4

local function getButtonInfo(button)
	local fakeButton = button:FindFirstChild("FakeButton")
	if not fakeButton then return end
	local textLabel = button:FindFirstChildOfClass("TextLabel")
	if not textLabel then return fakeButton end
	local stroke = textLabel:FindFirstChildOfClass("UIStroke")
	return fakeButton, textLabel, stroke
end

function ButtonUtility.HoverButton(button)
	local fakeButton, textLabel = button:FindFirstChild("FakeButton"), button:FindFirstChildOfClass("TextLabel")
	if not (fakeButton and textLabel) then return end
	local tween = TweenService:Create(fakeButton, ButtonUtility.HOVER_TWEEN_INFO, {Size = UDim2.new(1,5,1,5)})
	local textTween = TweenService:Create(textLabel, ButtonUtility.HOVER_TWEEN_INFO, {Size = UDim2.new(1,5,1,5)})
	textTween:Play()
	tween:Play()
	return tween
end

function ButtonUtility.ReverseHoverButton(button)
	local fakeButton, textLabel = button:FindFirstChild("FakeButton"), button:FindFirstChildOfClass("TextLabel")
	if not (fakeButton and textLabel) then return end
	local tween = TweenService:Create(fakeButton, ButtonUtility.HOVER_TWEEN_INFO, {Size = UDim2.fromScale(1,1)})
	local textTween = TweenService:Create(textLabel, ButtonUtility.HOVER_TWEEN_INFO, {Size = UDim2.fromScale(1,1)})
	textTween:Play()
	tween:Play()
	return tween
end

function ButtonUtility.SetButtonState(button, canAfford)
	button.FakeButton.BackgroundColor3 = canAfford and Colors.Buttons.Green or Colors.Buttons.Red
end

function ButtonUtility.ButtonPush(button)
	local activeTween = button:GetAttribute("ActiveTween")
	if activeTween then return end
	button:SetAttribute("ActiveTween",true)
	
	local fakeButton, textLabel, uiStroke = getButtonInfo(button)

	local tween = TweenService:Create(fakeButton, ButtonUtility.BOUNCY_BUTTON_TWEEN_INFO, {
		Size = fakeButton.Size + UDim2.fromOffset(ButtonUtility.BUTTON_OFFSET, ButtonUtility.BUTTON_OFFSET),
	})

	if textLabel then
		local textTween = TweenService:Create(textLabel, ButtonUtility.BOUNCY_BUTTON_TWEEN_INFO, {
			Size = textLabel.Size + UDim2.fromOffset(ButtonUtility.BUTTON_OFFSET/2, ButtonUtility.BUTTON_OFFSET/2)
		})
		local fakeButtonTween = TweenService:Create(fakeButton, ButtonUtility.BOUNCY_BUTTON_TWEEN_INFO, {
			BackgroundColor3 = Colors.Buttons.Activated
		})
		local strokeTween = TweenService:Create(uiStroke, ButtonUtility.BOUNCY_BUTTON_TWEEN_INFO, {
			Color = Colors.Buttons.StrokeActivated
		})

		fakeButtonTween:Play()
		strokeTween:Play()
		textTween:Play()
	end

	tween:Play()
	
	tween.Completed:Connect(function()
		fakeButton.Size = UDim2.fromScale(1,1)
		button:SetAttribute("ActiveTween",nil)
	end)
end


return ButtonUtility
