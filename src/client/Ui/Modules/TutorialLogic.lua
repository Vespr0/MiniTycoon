-- TutorialLogic Module
-- Handles tutorial phase logic and state management

local TutorialLogic = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Players = game:GetService("Players")
local Events = ReplicatedStorage.Events

-- Dependencies
local StorageUi = require(script.Parent.Storage)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.ClientPlacement)
local Trove = require(ReplicatedStorage.Packages.trove)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)
local TutorialUi = require(script.Parent.Tutorial)
local Signal = require(ReplicatedStorage.Packages.signal)

-- Events
TutorialLogic.PhaseChanged = Signal.new()
local TutorialRemoteEvent = Events.Tutorial

-- State
TutorialLogic.CurrentPhase = 0
local currentTrove = nil

-- Phase definitions
local PHASES_CHECKPOINTS = { 4 }
local FINAL_PHASE = 4

local function sendSavedPhaseToServer(phase: number)
	task.spawn(function()
		local success, error = Events.Tutorial:InvokeServer("SetPhase", phase)

		if not success then
			error(`Error sending saved tutorial phase to server: {error}`)
		end
	end)
end

-- Phase management
local function setPhase(phase: number)
	TutorialLogic.CurrentPhase = phase
	TutorialLogic.PhaseChanged:Fire(phase)
	sendSavedPhaseToServer(phase)

	-- If the phase is a checkpoint then save to server
	if table.find(PHASES_CHECKPOINTS, phase) then
		task.spawn(function()
			local success, error = TutorialRemoteEvent:InvokeServer("SetPhase", phase)
	
			if not success then
				error(`Error while saving tutorial phase to server: {error}`)
			end
		end)
	end
end

local function cleanupCurrentPhase()
	if currentTrove then
		currentTrove:Destroy()
		currentTrove = nil
	end
end

-- Phase handlers - modular functions that can be called by phase number
local phaseHandlers = {}

-- Phase 1: Player should open the storage
phaseHandlers[1] = function()
	TutorialUi.hideFocus3D()
	TutorialUi.focusToElement(TutorialUi.getMenuButton("Storage"))

	-- Wait for the Player to open the storage through the menu
	StorageUi.OpenedEvent:Wait()

	TutorialLogic.GoToPhase(2)
end

-- Phase 2: Player should click on CoalMine
phaseHandlers[2] = function()
	currentTrove = Trove.new()

	TutorialUi.toggleStorageTypeSelectors(false)
	TutorialUi.showFocus()
	TutorialUi.hideFocus3D()
	TutorialUi.focusToElement(TutorialUi.getStorageItem("CoalMine"))

	currentTrove:Add(StorageUi.ClosedEvent:Connect(function()
		TutorialLogic.GoToPhase(1)
	end))

	currentTrove:Add(StorageUi.ItemSelected:Connect(function(itemName: string)
		if string.find(itemName, "Mine") then
			TutorialLogic.GoToPhase(3)
		else
			-- If wrong item selected, stay in phase 2 and refocus on CoalMine
			TutorialLogic.GoToPhase(2)
		end
	end))
end

-- Phase 3: Player should place the CoalMine item
phaseHandlers[3] = function()
	currentTrove = Trove.new()

	TutorialUi.hideFocus()
	TutorialUi.showFocus3D()
	TutorialUi.focusTo3DPlotPosition(Vector2.new(-5, 0))

	-- Listen for successful placement - only proceed if it's a CoalMine
	currentTrove:Add(ClientPlacement.PlacementFinished:Connect(function(placedItemName: string)
		-- If the item is a mine go back to phase 4
		if string.find(placedItemName, "Mine") then
			TutorialLogic.GoToPhase(4)
		else
			TutorialLogic.GoToPhase(2)
		end
	end))

	-- If placement is aborted, go back to phase two
	currentTrove:Add(ClientPlacement.PlacementAborted:Connect(function()
		TutorialLogic.GoToPhase(2)
	end))
end

-- Phase 4: TutorialUi completion
phaseHandlers[4] = function()
	print("Tutorial Phase Four - CoalMine successfully placed!")

	TutorialUi.toggleStorageTypeSelectors(true)
	TutorialUi.hideFocus3D()
	TutorialUi.hideFocus()
end

-- Public function to go to a specific phase
function TutorialLogic.GoToPhase(phase: number)
	cleanupCurrentPhase()
	setPhase(phase)

	if phaseHandlers[phase] then
		phaseHandlers[phase]()
	else
		warn("Invalid tutorial phase:", phase)
	end
end

function TutorialLogic.Setup()
	-- Wait for data to sync, then start from saved phase
	task.spawn(function()
	    if ClientPlayerData.DataSynched then
	        TutorialLogic.StartFromSavedPhase()
	    else
	        if not ClientPlayerData.DataSynched then
	            ClientPlayerData.DataSynchedEvent:Wait()
	        end
	        TutorialLogic.StartFromSavedPhase()
	    end
	end)
end

function TutorialLogic.StartFromSavedPhase()
	-- Get saved phase from ClientPlayerData (will be added when TutorialAccess is created)
	local savedPhase = ClientPlayerData.Data.Tutorial and ClientPlayerData.Data.Tutorial.Phase or 1
	print("Saved phase is ", savedPhase)

	if FINAL_PHASE == savedPhase then return end

	task.spawn(function()
		TutorialLogic.GoToPhase(savedPhase)
	end)
end

function TutorialLogic.Cleanup()
	cleanupCurrentPhase()
	setPhase(0)
end

return TutorialLogic
