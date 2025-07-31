local Ui = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Modules
local Signal = require(ReplicatedStorage.Packages.signal)
local ClientLoader = require(script.Parent.Parent.ClientLoader)

-- Variables
local PlayerGui = Player.PlayerGui
Ui.ScreenSize = PlayerGui:FindFirstChildOfClass("ScreenGui").AbsoluteSize

-- Fusion
Ui.Fusion = require(ReplicatedStorage.Packages.fusion)
Ui.peek = Ui.Fusion.peek
Ui.scoped = Ui.Fusion.scoped

-- Ui Elements
Ui.Player = Players.LocalPlayer
Ui.PlayerGui = PlayerGui
Ui.ControlPanelGui = PlayerGui:WaitForChild("ControlPanel")
Ui.StorageGui = PlayerGui:WaitForChild("Storage")
Ui.ShopGui = PlayerGui:WaitForChild("Shop")
Ui.UnboxingGui = PlayerGui:WaitForChild("Unboxing")
Ui.IndexGui = PlayerGui:WaitForChild("Index")
Ui.PlacementMenuGui = PlayerGui:WaitForChild("PlacementMenu")
Ui.TutorialGui = PlayerGui:WaitForChild("Tutorial")
Ui.TopGui = PlayerGui:WaitForChild("TopGui") 

-- Constants
Ui.BUTTON_UNSELECTED_COLOR = Color3.fromRGB(27, 27, 27)
Ui.BUTTON_SELECTED_COLOR = Color3.fromRGB(255, 255, 255)
Ui.HOVER_INCREMENT = UDim2.fromOffset(5, 0)
Ui.MENU_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Sine)

Ui.UiLoadedEvent = Signal.new()


-- Modules
local SoundManager = require(ReplicatedStorage.Shared.Sound.SoundManager)

local CLEAR_FRAME_BLACKLIST = {
	"UIGridLayout",
	"UIListLayout",
}
function Ui.ClearFrame(frame)
	for _, uiElement: GuiBase2d in pairs(frame:GetChildren()) do
		if table.find(CLEAR_FRAME_BLACKLIST, uiElement.ClassName) then
			continue
		end
		uiElement:Destroy()
	end
end

function Ui.IsButton(instance)
	return instance:IsA("ImageButton") or instance:IsA("TextButton")
end

function Ui.GetUiElementsOverCursor()
	local mousePos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	local GuiObjects = PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
	return GuiObjects
end

function Ui.IsAGuiBase2D(instance)
	local classes = {
		"Frame",
		"ImageButton",
		"TextLabel",
		"ScrollingFrame",
		"TextButton",
	}
	for _, className in pairs(classes) do
		if instance:IsA(className) then
			return true
		end
	end
	return false
end

function Ui.PlaySound(directory)
	SoundManager.PlaySound("Ui/" .. directory, nil, 1)
end

function Ui.HoverTween(button, goal)
	local tween = TweenService:Create(button, Ui.MENU_TWEEN_INFO, { Position = goal })
	tween:Play()
end

function Ui.UpdateToggleButtonColor(button, isEnabled, enabledColor, disabledColor)
	enabledColor = enabledColor or Color3.fromRGB(255, 255, 255) -- White
	disabledColor = disabledColor or Color3.fromRGB(224, 47, 47) -- Red

	if button and button:IsA("GuiObject") then
		button.ImageColor3 = isEnabled and enabledColor or disabledColor
	end
end

-- function Ui.WaitForClientLoaded()
-- 	if not ClientLoader.ClientLoaded then
-- 		ClientLoader.ClientLoadedEvent:Wait()
-- 	end
-- end

-- function Ui.GetRotationTowardTarget(targetElement: GuiObject,originElement: GuiObject)
--     local pointerCenter = Ui.GetElementAbsoluteCenterPosition(originElement)
-- 	local targetCenter = Ui.GetElementAbsoluteCenterPosition(targetElement)

-- 	local delta = (targetCenter - pointerCenter).Unit

--     delta = Vector2.new(delta.X,delta.Y)

-- 	local angleInRadians = math.atan2(delta.Y, delta.X)
-- 	local angleInDegrees = math.deg(angleInRadians)

--     return angleInRadians, angleInDegrees
-- end

function Ui.GetElementCenterUDim2(element: GuiObject)
	-- Get the element's absolute position and size
	local absolutePos = element.AbsolutePosition
	local absoluteSize = element.AbsoluteSize

	-- Calculate the center point
	local centerX = absolutePos.X + absoluteSize.X / 2
	local centerY = absolutePos.Y + absoluteSize.Y / 2

	-- Get GUI inset to account for top bar
	local guiInset = GuiService:GetGuiInset()

	-- Adjust for GUI inset (mainly affects Y position)
	centerY = centerY + guiInset.Y

	return UDim2.fromOffset(centerX, centerY)
end

function Ui.GetScreenCenter()
	local screenGui = PlayerGui:FindFirstChildOfClass("ScreenGui")
	local screenSize = screenGui.AbsoluteSize
	return Vector2.new(screenSize.X / 2, screenSize.Y / 2)
end

return Ui
