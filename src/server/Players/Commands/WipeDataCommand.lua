local WipeDataCommand = {}

-- Services --
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules --
local PlayerDataManager = require(ServerScriptService.Server.Data.PlayerDataManager)

-- Setup --
function WipeDataCommand.Register(Utility)
    local Conch = Utility.Conch

	-- Register wipedata command using register_quick for simplicity
	Conch.register_quick("wipedata", function(userIdStr)
		local userId = tonumber(userIdStr)
		if not userId then
			Conch.log("error", "Invalid user ID: must be a number")
			return
		end
		
		local success = PlayerDataManager.WipeUserData(userId)
		if success then
			Conch.log("info", "Successfully wiped data for user ID: " .. tostring(userId))
		else
			Conch.log("error", "Failed to wipe data for user ID: " .. tostring(userId))
		end
	end, "admin")
end

return WipeDataCommand