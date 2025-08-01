local AdminCommands = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local AdminAccess = require(script.Parent.Parent.Data.DataAccessModules.AdminAccess)

-- Chat command handler
local function onPlayerChatted(player, message)
	local args = string.split(message, " ")
	local command = args[1]:lower()
	
	if command == "/wipedata" then
		if #args < 2 then
			-- Wipe own data
			local success, result = AdminAccess.WipePlayerData(player, player)
			if success then
				player:Kick("Your data has been wiped. Please rejoin the game.")
			else
				warn("Failed to wipe data for " .. player.Name .. ": " .. result)
			end
		else
			-- Wipe target player's data
			local targetName = args[2]
			local targetPlayer = Players:FindFirstChild(targetName)
			
			if targetPlayer then
				local success, result = AdminAccess.WipePlayerData(player, targetPlayer)
				if success then
					targetPlayer:Kick("Your data has been wiped by an admin. Please rejoin the game.")
					-- Notify admin
					local message = Instance.new("Message")
					message.Text = "Successfully wiped data for " .. targetPlayer.Name
					message.Parent = player.PlayerGui
					game:GetService("Debris"):AddItem(message, 5)
				else
					warn("Failed to wipe data for " .. targetPlayer.Name .. ": " .. result)
				end
			else
				warn("Player " .. targetName .. " not found")
			end
		end
		
	elseif command == "/wipeuserid" then
		if #args < 2 then
			warn("Usage: /wipeuserid <userId>")
			return
		end
		
		local targetUserId = tonumber(args[2])
		if not targetUserId then
			warn("Invalid userId: " .. args[2])
			return
		end
		
		local success, result = AdminAccess.WipeUserData(player.UserId, targetUserId)
		if success then
			-- Notify admin
			local message = Instance.new("Message")
			message.Text = "Successfully wiped data for userId " .. targetUserId
			message.Parent = player.PlayerGui
			game:GetService("Debris"):AddItem(message, 5)
			
			-- Kick player if online
			local targetPlayer = Players:GetPlayerByUserId(targetUserId)
			if targetPlayer then
				targetPlayer:Kick("Your data has been wiped by an admin. Please rejoin the game.")
			end
		else
			warn("Failed to wipe data for userId " .. targetUserId .. ": " .. result)
		end
		
	elseif command == "/inspectdata" then
		if #args < 2 then
			warn("Usage: /inspectdata <playerName or userId>")
			return
		end
		
		local target = args[2]
		local targetUserId = tonumber(target)
		
		-- Try to find by name first, then by userId
		if not targetUserId then
			local targetPlayer = Players:FindFirstChild(target)
			if targetPlayer then
				targetUserId = targetPlayer.UserId
			else
				warn("Player " .. target .. " not found")
				return
			end
		end
		
		local data, result = AdminAccess.InspectUserData(player.UserId, targetUserId)
		if data then
			print("=== Data for userId " .. targetUserId .. " ===")
			print("Level:", data.Level)
			print("Exp:", data.Exp)
			print("Cash:", data.Cash)
			print("Plot Level:", data.Plot.PlotLevel)
			print("Tutorial Finished:", data.Tutorial.TutorialFinished)
			print("Storage Items:", #data.Storage > 0 and data.Storage or "None")
			print("Placed Items:", #data.PlacedItems > 0 and #data.PlacedItems or "None")
		else
			warn("Failed to inspect data: " .. result)
		end
	end
end

function AdminCommands.Setup()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			onPlayerChatted(player, message)
		end)
	end)
	
	-- Handle players already in game
	for _, player in pairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			onPlayerChatted(player, message)
		end)
	end
end

return AdminCommands