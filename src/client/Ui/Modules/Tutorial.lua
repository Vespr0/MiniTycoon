-- Tutorial Module
-- Handles tutorial viewport frame positioning and arrow visibility

local Tutorial = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)

local MenuUi = require(script.Parent.Menu)
local StorageUi = require(script.Parent.Storage)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.ClientPlacement)
local Trove = require(ReplicatedStorage.Packages.trove)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)

-- Ui Elements
local TutorialGui = Ui.PlayerGui:WaitForChild("Tutorial")
local FocusElement = TutorialGui:WaitForChild("Focus")
local FocusElement3D = TutorialGui:WaitForChild("Focus3D")
FocusElement.Parent = script
local CurrentFocusElement = FocusElement:Clone()

-- Constants
local PULSE_TIME = 1 / 2
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

	local position = plot.Root.Position + Vector3.new(position2D.X, position2D.Y)
	-- Height bias
	position += Vector3.yAxis * (root.Size.Y / 2 + FocusElement3D.Size.Y / 2)
	focusTo3DPosition(position)
end

-- Player should open the storage
function Tutorial.StartPhaseOne()
	focusToElement(MenuUi.MainFrame:WaitForChild("Storage"))

	-- Wait for the Player to open the storage through the menu
	StorageUi.OpenedEvent:Wait()

	Tutorial.StartPhaseTwo()
end

-- Player should click on CoalMine, if for some reason he closes storage, go back to phase one
function Tutorial.StartPhaseTwo()
	showFocus()

	print("Phase 2 babey")
	local coalMine = StorageUi.WaitForItemInItemsFrame("CoalMine")
	focusToElement(coalMine)

	local trove = Trove.new()

	trove:Add(StorageUi.ClosedEvent:Connect(function()
		trove:Destroy()
		Tutorial.StartPhaseOne()
	end))

	trove:Add(StorageUi.ItemSelected:Connect(function(itemName: string)
		if itemName == "CoalMine" then
			trove:Destroy()
			Tutorial.StartPhaseThree()
			-- else
			-- 	Tutorial.StartPhaseTwo()
			-- 	trove:Destroy()
		end
	end))
end

-- Player should place the CoalMine item
function Tutorial.StartPhaseThree()
	-- Hide the focus element since we're now in placement mode
	hideFocus()
	showFocus3D()
	focusTo3DPlotPosition(Vector2.new(0, 0))

	local trove = Trove.new()

	-- Listen for successful placement - only proceed if it's a CoalMine
	trove:Add(ClientPlacement.PlacementFinished:Connect(function(placedItemName: string)
		warn(placedItemName, "THIS SHIT LAAAACED")
		if placedItemName == "CoalMine" then
			trove:Destroy()
			Tutorial.StartPhaseFour()
		end
	end))

	-- If placement is aborted, go back to phase two
	trove:Add(ClientPlacement.PlacementAborted:Connect(function()
		trove:Destroy()
		Tutorial.StartPhaseTwo()
	end))
end

-- Placeholder for the next tutorial phase
function Tutorial.StartPhaseFour()
	-- Add your next tutorial step here
	print("Tutorial Phase Four - CoalMine successfully placed!")

	hideFocus3d()
	hideFocus()
end

function Tutorial.Setup()
	-- TutorialGui.Enabled = true

	-- Don't start pulse here - it will be started when focusToElement is called
	-- task.spawn(function()
	-- 	Tutorial.StartPhaseOne()
	-- end)
end

return Tutorial
