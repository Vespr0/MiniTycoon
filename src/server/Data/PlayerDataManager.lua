local PlayerDataManager = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
local Server = ServerScriptService.Server

-- Modules --
local DataStoreModule = require(Packages.suphisdatastoremodule)
local DataUtility = require(Shared.Data.DataUtility)
--local Trove = require(Packages.trove)
local BridgeNet2 = require(Packages.BridgeNet2)
local PlayerDataReplication = require(Server.Data.PlayerDataReplication)
local DataAccess = require(Server.Data.DataAccess)
local PlayerDataStore = require(Server.Data.PlayerDataStore)

-- Wipe all data for a user by userId
function PlayerDataManager.WipeUserData(userId)
	-- First try to find existing datastore (for online players)
	local dataStore = DataStoreModule.find(DataUtility.GetDataScope("Player"), tostring(userId))

	if dataStore and dataStore.State == true then
		-- Player is online and datastore is open, wipe directly
		dataStore.Value = PlayerDataStore.DataTemplate
		local response = dataStore:Save()
		if response == "Saved" then
			print("PlayerDataManager.WipeUserData: Wiped data for online userId " .. tostring(userId))
			return true
		else
			error(
				"PlayerDataManager.WipeUserData: Failed to save wiped data for userId "
					.. tostring(userId)
					.. " - "
					.. response
			)
			return false
		end
	else
		-- Player is offline or datastore not open, create temporary datastore
		local tempDataStore = DataStoreModule.new(DataUtility.GetDataScope("Player"), tostring(userId))
		local response = tempDataStore:Open(PlayerDataStore.DataTemplate)

		if response ~= "Success" then
			tempDataStore:Destroy()
			error(
				"PlayerDataManager.WipeUserData: Failed to open datastore for userId "
					.. tostring(userId)
					.. " - "
					.. response
			)
			return false
		end

		-- Set to template and save
		tempDataStore.Value = PlayerDataStore.DataTemplate
		local saveResponse = tempDataStore:Save()

		-- Clean up
		tempDataStore:Destroy()

		if saveResponse == "Saved" then
			print("PlayerDataManager.WipeUserData: Wiped data for userId " .. tostring(userId))
			return true
		else
			error(
				"PlayerDataManager.WipeUserData: Failed to save wiped data for userId "
					.. tostring(userId)
					.. " - "
					.. saveResponse
			)
			return false
		end
	end
end

-- Setup --
function PlayerDataManager.Setup()
	Players.PlayerAdded:Connect(function(player)
		-- Replication.
		PlayerDataReplication.SetupPlayer(player)
		player:SetAttribute("DataLoaded", true)
	end)

	if RunService:IsStudio() then
		-- Wipe the user data of the test user.
		-- PlayerDataManager.WipeUserData(-1)
	end
end

return PlayerDataManager
