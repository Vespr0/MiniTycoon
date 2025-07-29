local Ui = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Variables
local PlayerGui = Player.PlayerGui
local ScreenSize = PlayerGui:FindFirstChildOfClass("ScreenGui").AbsoluteSize

-- Ui Elements
Ui.Player = Players.LocalPlayer
Ui.PlayerGui = PlayerGui
Ui.ControlPanelGui = PlayerGui:WaitForChild("ControlPanel")
Ui.StorageGui = PlayerGui:WaitForChild("Storage")
Ui.ShopGui = PlayerGui:WaitForChild("Shop")
Ui.UnboxingGui = PlayerGui:WaitForChild("Unboxing")
Ui.IndexGui = PlayerGui:WaitForChild("Index")
Ui.PlacementMenuGui = PlayerGui:WaitForChild("PlacementMenu")

-- Constants
Ui.BUTTON_UNSELECTED_COLOR = Color3.fromRGB(27, 27, 27)
Ui.BUTTON_SELECTED_COLOR = Color3.fromRGB(255, 255, 255)
Ui.HOVER_INCREMENT = UDim2.fromOffset(5,0)
Ui.MENU_TWEEN_INFO = TweenInfo.new(.15,Enum.EasingStyle.Sine)

-- Modules 
local SoundManager = require(ReplicatedStorage.Shared.Sound.SoundManager)

local CLEAR_FRAME_BLACKLIST = {
    "UIGridLayout",
    "UIListLayout"
}
function Ui.ClearFrame(frame)
	for _,uiElement:GuiBase2d in pairs(frame:GetChildren()) do
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
        "Frame";
        "ImageButton";
        "TextLabel";
        "ScrollingFrame";
        "TextButton";
    }
    for _,className in pairs(classes) do
        if instance:IsA(className) then
            return true
        end
    end
    return false
end

function Ui.PlaySound(directory)
	SoundManager.PlaySound("Ui/"..directory,nil,1)
end

function Ui.HoverTween(button,goal)
    local tween = TweenService:Create(button,Ui.MENU_TWEEN_INFO,{Position = goal})
    tween:Play()
end

--[[
    Updates a button's color based on a toggle state
    @param button GuiObject - The button to update
    @param isEnabled boolean - Whether the toggle is enabled
    @param enabledColor Color3 - Color when enabled (optional, defaults to white)
    @param disabledColor Color3 - Color when disabled (optional, defaults to red)
]]
function Ui.UpdateToggleButtonColor(button, isEnabled, enabledColor, disabledColor)
    enabledColor = enabledColor or Color3.fromRGB(255, 255, 255) -- White
    disabledColor = disabledColor or Color3.fromRGB(224, 47, 47) -- Red
    
    if button and button:IsA("GuiObject") then
        button.ImageColor3 = isEnabled and enabledColor or disabledColor
    end
end

--[[
    Calculates the center position of a GUI element in absolute coordinates
    @param element GuiObject - The GUI element to get center position for
    @return Vector2 - The absolute center position
]]
function Ui.GetElementCenter(element)
	local absolutePos = element.AbsolutePosition
	local absoluteSize = element.AbsoluteSize
	return Vector2.new(absolutePos.X + absoluteSize.X / 2, absolutePos.Y + absoluteSize.Y / 2)
end

function Ui.GetElementAbsoluteCenterPosition(element: GuiObject)
    -- local topLeftAbsolutePosition = element.AbsolutePosition - (element.AbsoluteSize * element.AnchorPoint)
    return element.AbsolutePosition + (element.AbsoluteSize / 2)
end

function Ui.GetRotationTowardTarget(targetElement: GuiObject,originElement: GuiObject)
    local pointerCenter = Ui.GetElementAbsoluteCenterPosition(originElement)
	local targetCenter = Ui.GetElementAbsoluteCenterPosition(targetElement)
	
	local delta = (targetCenter - pointerCenter).Unit

    delta = Vector2.new(delta.X,delta.Y)
	
	local angleInRadians = math.atan2(delta.Y, delta.X)
	local angleInDegrees = math.deg(angleInRadians)

    return angleInRadians, angleInDegrees
end

function Ui.GetAbsoluteUdim2FromElement(element: GuiObject)
	local absolutePosition = element.AbsolutePosition
	return UDim2.fromOffset(absolutePosition.X, absolutePosition.Y)
end

--[[
    Gets the center position of the screen
    @return Vector2 - The screen center position in absolute coordinates
]]
function Ui.GetScreenCenter()
	local screenGui = PlayerGui:FindFirstChildOfClass("ScreenGui")
	if screenGui then
		local screenSize = screenGui.AbsoluteSize
		return Vector2.new(screenSize.X / 2, screenSize.Y / 2)
	end
	-- Fallback if no ScreenGui found
	return Vector2.new(800, 600) -- Default screen center
end

--[[
    Calculates an optimal arrow position at a specified distance from target, biased towards screen center
    @param targetElement GuiObject - The element to point at
    @param distance number - Distance from target in pixels (default: 100)
    @param centerBias number - How much to bias towards center (0-1, default: 0.3)
    @return UDim2 - The calculated position for the arrow container
]]
function Ui.CalculateArrowPosition(targetElement, distance, centerBias)
	distance = distance or 100
	centerBias = math.clamp(centerBias or 0.3, 0, 1)
	
	local targetCenter = Ui.GetElementAbsoluteCenterPosition(targetElement)
	local screenCenter = Ui.GetScreenCenter()
	local screenGui = PlayerGui:FindFirstChildOfClass("ScreenGui")
	local screenSize = screenGui.AbsoluteSize
	
	-- Calculate direction from target to screen center
	local toCenter = (screenCenter - targetCenter).Unit
	
	-- If target is at screen center, use a default direction (pointing up-left)
	if toCenter.Magnitude == 0 then
		toCenter = Vector2.new(-0.707, -0.707) -- 45 degrees up-left
	end
	
	-- Calculate base position at specified distance from target
	local basePosition = targetCenter + (toCenter * distance)
	
	-- Apply center bias by interpolating between base position and a position closer to center
	local centerBiasPosition = targetCenter + (toCenter * (distance * (1 + centerBias)))
	local finalPosition = basePosition:lerp(centerBiasPosition, centerBias)
	
	-- Ensure the arrow stays within screen bounds with some padding
	local padding = 50
	finalPosition = Vector2.new(
		math.clamp(finalPosition.X, padding, screenSize.X - padding),
		math.clamp(finalPosition.Y, padding, screenSize.Y - padding)
	)
	
	-- Convert to UDim2 for UI positioning
	return UDim2.fromOffset(finalPosition.X, finalPosition.Y)
end

--[[
    Alternative algorithm that tries multiple positions around the target and picks the best one
    @param targetElement GuiObject - The element to point at
    @param distance number - Distance from target in pixels (default: 100)
    @param numCandidates number - Number of candidate positions to test (default: 8)
    @return UDim2 - The calculated position for the arrow container
]]
function Ui.CalculateOptimalArrowPosition(targetElement, distance, numCandidates)
	distance = distance or 100
	numCandidates = numCandidates or 8
	
	local targetCenter = Ui.GetElementAbsoluteCenterPosition(targetElement)
	local screenCenter = Ui.GetScreenCenter()
	local screenGui = PlayerGui:FindFirstChildOfClass("ScreenGui")
	local screenSize = screenGui.AbsoluteSize
	
	local bestPosition = nil
	local bestScore = -math.huge
	
	-- Test positions in a circle around the target
	for i = 0, numCandidates - 1 do
		local angle = (i / numCandidates) * 2 * math.pi
		local candidatePosition = targetCenter + Vector2.new(
			math.cos(angle) * distance,
			math.sin(angle) * distance
		)
		
		-- Score this position based on:
		-- 1. Distance to screen center (closer is better)
		-- 2. Whether it's within screen bounds
		-- 3. Avoid corners and edges
		
		local distanceToCenter = (candidatePosition - screenCenter).Magnitude
		local centerScore = 1 / (1 + distanceToCenter / 100) -- Normalize and invert
		
		-- Boundary score - penalize positions near edges
		local edgeDistance = math.min(
			candidatePosition.X,
			candidatePosition.Y,
			screenSize.X - candidatePosition.X,
			screenSize.Y - candidatePosition.Y
		)
		local boundaryScore = math.clamp(edgeDistance / 100, 0, 1)
		
		-- Out of bounds penalty
		local inBounds = candidatePosition.X >= 0 and candidatePosition.Y >= 0 and
						candidatePosition.X <= screenSize.X and candidatePosition.Y <= screenSize.Y
		local boundsScore = inBounds and 1 or -10
		
		local totalScore = centerScore + boundaryScore + boundsScore
		
		if totalScore > bestScore then
			bestScore = totalScore
			bestPosition = candidatePosition
		end
	end
	
	-- Fallback to simple center-biased position if no good position found
	if not bestPosition then
		local toCenter = (screenCenter - targetCenter).Unit
		bestPosition = targetCenter + (toCenter * distance)
	end
	
	-- Ensure final position is within bounds
	local padding = 50
	bestPosition = Vector2.new(
		math.clamp(bestPosition.X, padding, screenSize.X - padding),
		math.clamp(bestPosition.Y, padding, screenSize.Y - padding)
	)
	
	return UDim2.fromOffset(bestPosition.X, bestPosition.Y)
end

return Ui