local TutorialService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Events = ReplicatedStorage.Events

-- Modules --
local TutorialAccess = require(Server.Data.DataAccessModules.TutorialAccess)

local function onRequest(player, type, ...)
	local args = { ... }

	if type == "SetPhase" then
		local phase = args[1]
		if phase and typeof(phase) == "number" then
			TutorialAccess.SaveTutorialPhase(player, phase)
			return true
		else
			return false, "Invalid `phase` value"
		end
	end

	return false, "Invalid request type"
end

function TutorialService.Setup()
	Events.Tutorial.OnServerInvoke = onRequest
end

return TutorialService
