local ClientPlacement = {}

-- Modules --
local Packages = game:GetService("ReplicatedStorage").Packages
local Signal = require(Packages.signal)
local PlacementMenuUi = require(script.Parent.Parent.Parent.Ui.Modules.PlacementMenu)

-- Variables --
local currentPlacement = nil

-- Signals --
-- ClientPlacement.PlacementStatusUpdated = Signal.new()
ClientPlacement.PlacementFinished = Signal.new()
ClientPlacement.PlacementAborted = Signal.new()
ClientPlacement.PlacementRotated = Signal.new()

-- Functions --

-- Returns the current placement status
function ClientPlacement.IsPlacing()
	return currentPlacement ~= nil
end

-- Initiates the placement process for an item
function ClientPlacement.StartPlacing(itemName, model, isMoving)
	if currentPlacement then
		error("Already placing or moving.")
		return
	end
	if not itemName then
		error("itemName must not be nil.")
		return
	end
	
	-- Create new placement instance
	local PlacementInstance = require(script.Parent.PlacementInstance)
	currentPlacement = PlacementInstance.new(itemName, model, isMoving)
		
	-- Update status and open UI
	PlacementMenuUi.Open()

	ClientPlacement.PlacementFinished:Connect(function()
		currentPlacement = nil
	end)

	ClientPlacement.PlacementAborted:Connect(function()
		currentPlacement = nil
	end)
end

-- Gets the current placement instance (for advanced usage)
function ClientPlacement.GetCurrentPlacement()
	return currentPlacement
end

return ClientPlacement