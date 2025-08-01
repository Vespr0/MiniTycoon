local PlayerOrderedDataManager = {}

-- Services --
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server
local OrderedDataModules = script.Parent.OrderedDataModules

-- Constants --
PlayerOrderedDataManager.Errors = {
	invalidParameters = "Invalid parameter, %q is nil",
	updateFailed = "Failed to update ordered datastore.",
}
local ERRORS = PlayerOrderedDataManager.Errors

-- Variables --
local orderedDataStores = {}

-- Local Functions --

local function getOrderedDataStore(name)
	if not orderedDataStores[name] then
		orderedDataStores[name] = DataStoreService:GetOrderedDataStore(name)
	end
	return orderedDataStores[name]
end

-- Functions --

function PlayerOrderedDataManager.GetParameters(...)
	local args = { ... }
	local returnedArgs = {}

	for i, v in args do
		returnedArgs[i] = v
		if v == nil then
			error(string.format(ERRORS.invalidParameters, i))
		end
	end
	if #returnedArgs > 0 then
		return table.unpack(returnedArgs)
	end

	return nil
end

function PlayerOrderedDataManager.UpdatePlayerData(dataStoreName, player, value)
	local success, result = pcall(function()
		local orderedStore = getOrderedDataStore(dataStoreName)
		return orderedStore:SetAsync(tostring(player.UserId), value)
	end)

	if not success then
		error(ERRORS.updateFailed .. " " .. tostring(result))
	end

	return success
end

function PlayerOrderedDataManager.GetTopPlayers(dataStoreName, pageSize, isAscending)
	pageSize = pageSize or 10
	isAscending = isAscending or false

	local success, result = pcall(function()
		local orderedStore = getOrderedDataStore(dataStoreName)
		local pages = orderedStore:GetSortedAsync(isAscending, pageSize)
		return pages:GetCurrentPage()
	end)

	if success then
		return result
	else
		error(ERRORS.updateFailed .. " " .. tostring(result))
		return {}
	end
end

function PlayerOrderedDataManager.Setup()
	for _, orderedDataModule in pairs(OrderedDataModules:GetChildren()) do
		if orderedDataModule:IsA("ModuleScript") then
			local module = require(orderedDataModule)
			if module.Init then
				module.Init()
			end
		end
	end

	-- local topPlayers = PlayerOrderedDataManager.GetTopPlayers("Level", 10, false)
	-- print("Top 10 players by level:")
	-- for i, playerData in ipairs(topPlayers) do
	-- 	print(i .. ". " .. playerData.key .. " - Level: " .. playerData.value)
	-- end
end

return PlayerOrderedDataManager
