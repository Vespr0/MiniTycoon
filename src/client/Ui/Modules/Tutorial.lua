-- Tutorial Module
-- Handles tutorial UI elements, viewport frame positioning and arrow visibility

local Tutorial = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local MenuUi = require(script.Parent.Menu)
local StorageUi = require(script.Parent.Storage)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)

-- Ui Elements
local TutorialGui = Ui.PlayerGui:WaitForChild("Tutorial")
local FocusElement = TutorialGui:WaitForChild("Focus")
local FocusElement3D = TutorialGui:WaitForChild("Focus3D")
FocusElement.Parent = script
local CurrentFocusElement = FocusElement:Clone()

-- Constants
local PULSE_BASE_SIZE = Vector2.new(0, 0) -- Will be set when focusing an element
local PULSE_INTENSITY = 15 -- Single number for pulse expansion
local PULSE_3D_BASE_SIZE = 4

-- Variables
local scope = Ui.scoped(Ui.Fusion)

local pulseValue = scope:Value(PULSE_INTENSITY) -- Single number representing pulse intensity
local springPulse = scope:Spring(pulseValue, 4, 0) -- Lower damping for natural oscillation

-- Observer for spring pulse changes - applies the pulse to both axes
scope:Observer(springPulse):onChange(function()
	local intensity = Ui.peek(springPulse)
	CurrentFocusElement.Size = UDim2.fromOffset(PULSE_BASE_SIZE.X + intensity, PULSE_BASE_SIZE.Y + intensity)
	FocusElement3D.Size = Vector3.new(PULSE_3D_BASE_SIZE + intensity / 10, 0.1, PULSE_3D_BASE_SIZE + intensity / 10)
end)

local function isFocusElementDestroyed()
	return not (CurrentFocusElement and CurrentFocusElement.Parent)
end

local function regenerateFocusElement()
	CurrentFocusElement = FocusElement:Clone()
end

local function startPulse()
	-- Just give the spring an initial velocity to start oscillating
	-- The underdamped spring will naturally pulse back and forth
	springPulse:setVelocity(-PULSE_INTENSITY * 2)
end

local function showFocus3D()
	FocusElement3D.Parent = workspace
end

local function hideFocus3d()
	FocusElement3D.Parent = script
end

local function showFocus()
	if CurrentFocusElement and CurrentFocusElement.Parent then
		CurrentFocusElement.Visible = true
	end
end

local function hideFocus()
	if CurrentFocusElement and CurrentFocusElement.Parent then
		CurrentFocusElement.Visible = false
	else
		-- If focus element doesn't exist or has no parent, remove it completely
		if CurrentFocusElement then
			CurrentFocusElement:Destroy()
		end
	end
end

local function focusToElement(element: GuiObject)
	if isFocusElementDestroyed() then
		regenerateFocusElement()
	end

	CurrentFocusElement.Position = UDim2.fromScale(0.5, 0.5)

	PULSE_BASE_SIZE = element.AbsoluteSize + Vector2.new(10, 10)
	CurrentFocusElement.Parent = element

	-- Restart pulse animation with new size
	startPulse()
	showFocus()
end

local function focusTo3DPosition(position: Vector3)
	FocusElement3D.Position = position

	FocusElement3D.Parent = workspace
end

local function focusTo3DPlotPosition(position2D: Vector2)
	local plot = PlotUtility.GetPlotFromPlayer(Player)
	local root = plot.Root

	local position = plot.Root.Position + Vector3.new(position2D.X, 0, position2D.Y)
	-- Height bias
	position += Vector3.yAxis * (root.Size.Y / 2 + FocusElement3D.Size.Y / 2)
	focusTo3DPosition(position)
end

-- Public API - expose the local functions
Tutorial.showFocus3D = showFocus3D
Tutorial.hideFocus3D = hideFocus3d
Tutorial.showFocus = showFocus
Tutorial.hideFocus = hideFocus
Tutorial.focusToElement = focusToElement
Tutorial.focusTo3DPosition = focusTo3DPosition
Tutorial.focusTo3DPlotPosition = focusTo3DPlotPosition

-- Utility functions
function Tutorial.getMenuButton(name: string)
	return MenuUi.MainFrame:WaitForChild(name)
end

function Tutorial.getStorageItem(name: string)
	return StorageUi.WaitForItemInItemsFrame(name)
end

function Tutorial.toggleStorageTypeSelectors(bool: boolean)
	Ui.StorageGui.MainFrame.TypeSelectors.Visible = bool
end

function Tutorial.Setup()
	TutorialGui.Enabled = true
end

return Tutorial
