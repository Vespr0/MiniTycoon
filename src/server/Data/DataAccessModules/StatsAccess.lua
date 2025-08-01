local StatsAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local DataUtility = DataAccess.DataUtility

function StatsAccess.GetStat(...)
    local args = DataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local statName = args[2]

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    return dataStore.Value.Stats[statName]
end

function StatsAccess.IncrementStat(...)
    local args = DataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local statName = args[2]
    local value = args[3]

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    dataStore.Value.Stats[statName] = value
    warn(player.UserId.." stats updated. "..tostring(statName).." is now "..tostring(value))
end

function StatsAccess.Init()
end

return StatsAccess