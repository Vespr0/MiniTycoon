local KickCommand = {}

-- Services --
local Players = game:GetService("Players")

-- Setup --
function KickCommand.Register(Utility)
	local Conch = Utility.Conch

	-- Register kick command using register_quick for simplicity
	Conch.register_quick("kick", function(username, reason)
		if not username or username == "" then
			Conch.log("error", "Username is required")
			return
		end
        
		local targetPlayer = Players:FindFirstChild(username)
		if not targetPlayer then
			Conch.log("error", "Player '" .. username .. "' is not in the game")
			return
		end

		-- Default reason if none provided
		local kickReason = reason or "You have been kicked by an administrator"

		-- Kick the player
		targetPlayer:Kick(kickReason)

		Conch.log(
			"info",
			"Successfully kicked player: "
				.. targetPlayer.Name
				.. " (ID: "
				.. tostring(targetPlayer.UserId)
				.. ") - Reason: "
				.. kickReason
		)
	end, "admin")
end

return KickCommand
