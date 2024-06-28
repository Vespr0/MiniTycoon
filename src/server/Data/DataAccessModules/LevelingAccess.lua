local LevelingAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local PlayerDataAccess = require(script.Parent.Parent.PlayerDataAccess)
local DataUtility = PlayerDataAccess.DataUtility
local LevelingUtil = require(Shared.Data.LevelingUtil)

function LevelingAccess.GiveExp(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local amount = args[2]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    local level = dataStore.Value.Level
    local exp = dataStore.Value.Exp
    
    -- Calculate new values.
    local newLevel,newExp = LevelingUtil.GetLevelAndExpFromExpGain(level,exp,amount)

    -- Set new Values.
    dataStore.Value.Level = newLevel
    dataStore.Value.Exp = newExp

    -- Update
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Leveling"),dataStore.Value.Exp,dataStore.Value.Level)
end

function LevelingAccess.ResetLeveling(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    dataStore.Value.Level = 1
    dataStore.Value.Exp = 0
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Leveling"),dataStore.Value.Exp,dataStore.Value.Level)
end

function LevelingAccess.Get(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    
    return dataStore.Value.Level,dataStore.Value.Exp
end

function LevelingAccess.Setup()
    for _,player in Players:GetPlayers() do
        LevelingAccess.ResetLeveling(player)
    end
end

return LevelingAccess