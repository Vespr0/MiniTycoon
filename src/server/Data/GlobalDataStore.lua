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
	Stocks = {}
}

local function stateChanged(state,dataStore)
    --print("The datastore's state is "..tostring(dataStore.State))
    while dataStore.State == false do
        if dataStore:Open(dataTemplate) ~= "Success" then warn("Failed to open global datastore, retrying..."); task.wait(6) end
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