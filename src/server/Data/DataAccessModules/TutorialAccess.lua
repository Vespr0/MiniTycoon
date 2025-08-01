local TutorialAccess = {}

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)

function TutorialAccess.SetTutorialFinished(...)
	local player, finished = DataAccess.GetParameters(...)
	if not (player and finished ~= nil) then return end

	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then return end

	if typeof(finished) ~= "boolean" then error("Attempted to set non-boolean tutorial finished status for player", player.Name, ":", finished); return end

	-- Set tutorial finished status
	dataStore.Value.Tutorial.TutorialFinished = finished

	-- Update client
	DataAccess.PlayerDataChanged:Fire(player, "Tutorial", "TutorialFinished", finished)
end

function TutorialAccess.SaveTutorialPhase(...)
	local player, phase = DataAccess.GetParameters(...)
	if not (player and phase) then return end
	
	if typeof(phase) ~= "number" then error("Attempted to save non-numeric tutorial phase for player", player.Name, ":", phase); return end

	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then return end

	-- Save the current tutorial phase
	dataStore.Value.Tutorial.SavedTutorialPhase = phase

	-- Update client
	print("huh")
	DataAccess.PlayerDataChanged:Fire(player, "Tutorial", "SavedTutorialPhase", phase)
end

function TutorialAccess.IsTutorialFinished(...)
	local player = DataAccess.GetParameters(...)
	if not player then return end

	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then return end

	return dataStore.Value.Tutorial.TutorialFinished
end

function TutorialAccess.GetSavedPhase(...)
	local player = DataAccess.GetParameters(...)
	if not player then return end

	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then return end

	return dataStore.Value.Tutorial.SavedTutorialPhase
end

return TutorialAccess