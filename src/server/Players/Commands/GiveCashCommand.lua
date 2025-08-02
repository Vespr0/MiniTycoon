local GiveCashCommand = {}

-- Services --
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules --
local CashAccess = require(ServerScriptService.Server.Data.DataAccessModules.CashAccess)

-- Setup --
function GiveCashCommand.Register(Utility)
	local Conch = Utility.Conch

	-- Register givecash command using register_quick for simplicity
	Conch.register_quick("givecash", function(username, amountStr)
		if not username or username == "" then
			Conch.log("error", "Username is required")
			return
		end

		if not amountStr or amountStr == "" then
			Conch.log("error", "Amount is required")
			return
		end

		local amount = tonumber(amountStr)
		if not amount then
			Conch.log("error", "Amount must be a valid number")
			return
		end

		if amount <= 0 then
			Conch.log("error", "Amount must be greater than 0")
			return
		end

		local targetPlayer = Players:FindFirstChild(username)
		if not targetPlayer then
			Conch.log("error", "Player '" .. username .. "' is not in the game")
			return
		end

		-- Give cash to the player
		CashAccess.GiveCash(targetPlayer, amount)

		-- Get current cash for confirmation
		local currentCash = CashAccess.GetCash(targetPlayer)

		Conch.log(
			"info",
			"Successfully gave "
				.. tostring(amount)
				.. " cash to player: "
				.. targetPlayer.Name
				.. " (ID: "
				.. tostring(targetPlayer.UserId)
				.. ") - Current cash: "
				.. tostring(currentCash)
		)
	end, "admin")
end

return GiveCashCommand