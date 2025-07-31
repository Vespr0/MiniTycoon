local PlayerDataStore = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Modules --
local DataStoreModule = require(Packages.suphisdatastoremodule)
local DataUtility = require(Shared.Data.DataUtility)

local dataTemplate = {
	-- Stocks
	Stocks = {},
}

local function stateChanged(state, dataStore)
	--print("The datastore's state is "..tostring(dataStore.State))
	local startTime = tick()
	local timeout = 60 -- 60 seconds timeout

	while dataStore.State == false do
		if tick() - startTime > timeout then
			error("📋 Failed to open global datastore: timeout after " .. timeout .. " seconds")
		end

		if dataStore:Open(dataTemplate) ~= "Success" then
			print("📋 Failed to open global datastore, retrying...")
			task.wait(6)
		end
	end
end

function PlayerDataStore.Setup()
	local dataStore = DataStoreModule.new(DataUtility.GetDataScope("Global"))
	dataStore.StateChanged:Connect(stateChanged)

	game:BindToClose(function()
		if dataStore then
			dataStore:Destroy()
		end
	end)
end

return PlayerDataStore
