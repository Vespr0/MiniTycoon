local RejoinCommand = {}

-- Services --
local TeleportService = game:GetService("TeleportService")

-- Setup --
function RejoinCommand.Register(Utility)
	local Conch = Utility.Conch

	-- Register rejoin command using register_quick for simplicity
	Conch.register_quick("rejoin", function()
		-- Get the player who executed the command
		local context = Conch.get_command_context()
		local user = context.executor
        local player = user.player

		if not player then
			Conch.log("error", "Could not identify command executor")
			return
		end
		
		Conch.log("info", `Teleporting player to same server "{player.Name}"`)
		
        local teleportOptions = Instance.new('TeleportOptions')
		teleportOptions.ServerInstanceId = game.JobId

		-- Teleport the player back to the same game
		local success, errorMessage = pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, {player}, teleportOptions)
		end)
		
		if not success then
			Conch.log("error", "Failed to rejoin: " .. tostring(errorMessage))
		end
	end, "admin")
end

return RejoinCommand