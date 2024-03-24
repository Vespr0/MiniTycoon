local PlayerDataManager = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
local Server = ServerScriptService.Server
local ServerPlayerData = ServerStorage:WaitForChild("ServerPlayerData")

-- Modules --
local DataStoreModule = require(Packages.suphisdatastoremodule)
local DataUtility = require(Shared.Data.DataUtility)
--local Trove = require(Packages.trove)
local BridgeNet2 = require(Packages.BridgeNet2)
local PlayerDataReplication = require(Server.Data.PlayerDataReplication)
local PlayerDataAccess = require(Server.Data.PlayerDataAccess)

-- Variables --
local templateKeys = {
    "Cash";
    "Level";
    "Exp";
}

-- Functions --
--[[local function loadData(state,dataStore,dataFolder)
    if state ~= true then return end
    for _,name in templateKeys do
        print(dataStore.Value[name])
        print(dataFolder[name].Value)
        dataFolder[name].Value = dataStore.Value[name]
    end
    for id,amount in pairs(dataStore.Value.Storage) do
        print(id.."/"..amount)
        local item = Instance.new("IntValue")
        item.Name = id
        item.Value = amount
        item.Parent = dataFolder.Storage
    end
end]]

-- Setup --
function PlayerDataManager.Setup()
    PlayerDataReplication.Setup()
    PlayerDataAccess.Setup()
    Players.PlayerAdded:Connect(function(player)
        --[[local dataFolder = DataUtility.CreateDataFolder()
        dataFolder.Parent = ServerPlayerData
        dataFolder.Name = player.UserId
        -- Plot value.
        local plotValue = Instance.new("StringValue")
        plotValue.Name = "Plot"
        plotValue.Parent = player]]
        -- Datastore.
        --local dataStore = DataStoreModule.new(DataUtility.GetDataScope("Player"),player.UserId)
        --[[dataStore.StateChanged:Connect(function(state,dataStore)
            loadData(state,dataStore,dataFolder)
        end)]]
        -- Replication.
        PlayerDataReplication.SetupPlayer(player)
        PlayerDataAccess.GiveStorageItems(player,1,1)
        PlayerDataAccess.GiveStorageItems(player,4,1)
        PlayerDataAccess.GiveStorageItems(player,11,1)
        player:SetAttribute("DataLoaded",true)
    end)
    Players.PlayerRemoving:Connect(function(player)
        Debris:AddItem(ServerPlayerData:FindFirstChild(player.UserId),5)
    end)
end

return PlayerDataManager