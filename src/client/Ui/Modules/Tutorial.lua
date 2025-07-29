-- Tutorial Module
-- Handles tutorial viewport frame positioning and arrow visibility

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Import UI utility for accessing UI elements
local Ui = require(script.Parent.Parent.UiUtility)
local StorageUi = require(script.Parent.Storage)
local ShopUi = require(script.Parent.Shop)

local Tutorial = {}

-- Get the Tutorial GUI and its components
local TutorialGui = PlayerGui:WaitForChild("Tutorial")
local ViewportFrame = TutorialGui:WaitForChild("ViewportFrame")
local TutorialArrow = ViewportFrame:WaitForChild("TutorialArrow") -- This is a MeshPart, not a UI element

-- Default tween info for smooth animations
local DEFAULT_TWEEN_INFO = TweenInfo.new(
	0.3, -- Duration
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out,
	0, -- Repeat count
	false, -- Reverses
	0 -- Delay
)

-- Arrow positioning constants
local ARROW_DISTANCE = 50 -- Distance from target in pixels

function Tutorial.PointArrowAtAngle(angle)
	local arrowTween =
		TweenService:Create(TutorialArrow, DEFAULT_TWEEN_INFO, { CFrame = CFrame.Angles(math.rad(angle), 0, 0) })

	-- Play the tween
	arrowTween:Play()

	return arrowTween
end

function Tutorial.ShowArrow(animate)
	animate = animate ~= false -- Default to true unless explicitly false

	if animate then
		-- Animate the arrow appearing (MeshParts use Transparency property)
		local showTween = TweenService:Create(
			TutorialArrow,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Transparency = 0 }
		)
		showTween:Play()
		return showTween
	else
		-- Show immediately
		TutorialArrow.Transparency = 0
		return nil
	end
end

function Tutorial.HideArrow(animate)
	animate = animate ~= false -- Default to true unless explicitly false

	if animate then
		-- Animate the arrow disappearing (MeshParts use Transparency property)
		local hideTween = TweenService:Create(
			TutorialArrow,
			TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ Transparency = 1 }
		)

		hideTween:Play()

		return hideTween
	else
		-- Hide immediately
		TutorialArrow.Transparency = 1
		return nil
	end
end

function Tutorial.Point(waypointElement, angle, showArrow)
	local position = Ui.GetAbsoluteUdim2FromElement(waypointElement)

	local positionTween = TweenService:Create(ViewportFrame, DEFAULT_TWEEN_INFO, { Position = position })
	positionTween:Play()

	-- Rotate arrow to the specified angle
	local arrowTween = Tutorial.PointArrowAtAngle(angle)

	-- Show arrow if requested
	if showArrow then
		Tutorial.ShowArrow()
	end

	return arrowTween
end

-- function Tutorial.FlipArrow()
-- 	local flipTween = TweenService:Create(
-- 		TutorialArrow,
-- 		TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true),
-- 		{ CFrame = TutorialArrow.CFrame * CFrame.Angles(0, 0, math.rad(180)) }
-- 	)
-- 	flipTween:Play()
-- 	flipTween.Completed:Wait()
-- 	return flipTween
-- end

function Tutorial.StartBounceAnimation()
	local tween = TweenService:Create(
		TutorialArrow,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, true),
		{ Size = TutorialArrow.Size + Vector3.new(0, 0, 1 / 2) }
	)

	task.spawn(function()
		while true do
			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

function Tutorial.Setup()
	Tutorial.HideArrow()


	-- task.spawn(function()
	-- 	task.wait(4)

	-- 	Tutorial.StartBounceAnimation()

	-- 	local menuGui = Ui.PlayerGui:WaitForChild("Menu")
	-- 	local storageButton = menuGui.MainFrame:WaitForChild("Storage")
	-- 	local storageWaypoint = storageButton:WaitForChild("Waypoint")
 
	-- 	Tutorial.Point(storageWaypoint, 180, true) 

	-- 	StorageUi.OpenedEvent:Wait()

	-- 	local storageMainFrameWaypoint =
	-- 		Ui.PlayerGui:WaitForChild("Storage"):WaitForChild("Waypoint")

	-- 	Tutorial.Point(storageMainFrameWaypoint, 0, true) 

	-- 	-- ShopUi.OpenedEvent:Wait()
	-- end)
end

return Tutorial
