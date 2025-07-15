local Tween = {}

-- Services
local TweenService = game:GetService("TweenService")
-- Modules
local Ui = require(script.Parent.Parent.Parent.UiUtility)

local function getButtonInfo(button)
	local fakeButton = button:FindFirstChild("FakeButton")
	if not fakeButton then return end
	local textLabel = button:FindFirstChildOfClass("TextLabel")
	if not textLabel then return fakeButton end
	local stroke = textLabel:FindFirstChildOfClass("UIStroke")
	return fakeButton,textLabel,stroke
end

function Tween.Generic(uiElement,goals,tweenInfo: TweenInfo?)
	local tween = TweenService:Create(uiElement,tweenInfo or Ui.MENU_TWEEN_INFO,goals)
	tween:Play()
end

function Tween.Popup(frame,goal)
	local tween = TweenService:Create(frame,Ui.MENU_TWEEN_INFO,{Position = goal})
	tween:Play()
end


-- ButtonPush moved to PurchaseButtonUtility.lua


-- HoverButton and ReverseHoverButton moved to PurchaseButtonUtility.lua

function Tween.Color(button,goal)
	local tween = TweenService:Create(button,Ui.MENU_TWEEN_INFO,{ImageColor3 = goal})
	tween:Play()
end

return Tween
