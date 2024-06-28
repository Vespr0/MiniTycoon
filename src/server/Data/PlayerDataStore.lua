local PlayerDataStore = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Modules --
local DataStoreModule = require(Packages.suphisdatastoremodule)
local DataUtility = require(Shared.Data.DataUtility)

local ServerPlayerData = ServerStorage.ServerPlayerData

local dataTemplate = {
    -- Numbers --
    Level = 1;
    Exp = 0;
    Cash = 0;
    -- Tables --
    Storage = {
        -- 1 dropper, 5 belts and 1 forge.
        CoalMine = 1;
        OldBelt = 5;
        OldForge = 1;
    };
    PlacedItems = {
    };
    -- Session --
    Session = { 
        FirstPlayed = nil;
        LastPlayed = nil;
        TimePlayed = 0;
    };
    -- Services --
    Services = {
        Offers = nil;
        OffersExpiration = nil;
    };
    -- Stats --
    Stats = {
        OffersBought = 0;
    }
}

local function stateChanged(state,dataStore)
    --print("The datastore's state is "..tostring(dataStore.State))
    while dataStore.State == false do
        if dataStore:Open(dataTemplate) ~= "Success" then warn("Failed to open datastore, retrying..."); task.wait(6) end
        --print("The datastore's state is "..tostring(dataStore.State))
    end
end

function PlayerDataStore.Setup()
    -- Player joins.
    Players.PlayerAdded:Connect(function(player)
        local dataStore = DataStoreModule.new(DataUtility.GetDataScope("Player"), player.UserId)
        dataStore.StateChanged:Connect(stateChanged)
        stateChanged(dataStore.State, dataStore)
    end)
    -- Player leaves.
    Players.PlayerRemoving:Connect(function(player)
        local dataStore = DataStoreModule.find(DataUtility.GetDataScope("Player"), player.UserId)
        -- If the player leaves, the datastore object is destroyed, allowing the retry loop to stop.
        if dataStore ~= nil then dataStore:Destroy() end
    end)
end

return PlayerDataStore