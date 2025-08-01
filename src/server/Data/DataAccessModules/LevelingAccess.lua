local LevelingAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local DataUtility = DataAccess.DataUtility
local LevelingUtil = require(Shared.Data.LevelingUtil)
local OnboardingAccess = require(script.Parent.OnboardingAccess)
local LevelingOrdered = require(script.Parent.Parent.OrderedDataModules.LevelingOrdered)

function LevelingAccess.GiveExp(...)
	local player, amount = DataAccess.GetParameters(...)
	if not (player and amount) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    local level = dataStore.Value.Level
    local exp = dataStore.Value.Exp
    
    -- Calculate new values.
    local newLevel,newExp = LevelingUtil.GetLevelAndExpFromExpGain(level,exp,amount)

    -- Set new Values.
    dataStore.Value.Level = newLevel
    dataStore.Value.Exp = newExp

    -- Update OrderedDataStore if level changed
    if newLevel ~= level then
        LevelingOrdered.UpdatePlayerLevel(player, newLevel)
    end

    -- Check for level-based onboarding steps
    OnboardingAccess.CheckLevelSteps(player, newLevel)

    -- Update
    DataAccess.PlayerDataChanged:Fire(player,"Leveling",dataStore.Value.Exp,dataStore.Value.Level)
end

function LevelingAccess.ResetLeveling(...)
	local player = DataAccess.GetParameters(...)
	if not player then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    dataStore.Value.Level = 1
    dataStore.Value.Exp = 0
    
    -- Update OrderedDataStore
    LevelingOrdered.UpdatePlayerLevel(player, 1)
    
    DataAccess.PlayerDataChanged:Fire(player,"Leveling",dataStore.Value.Exp,dataStore.Value.Level)
end

function LevelingAccess.Get(...)
	local player = DataAccess.GetParameters(...)
	if not player then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    
    return dataStore.Value.Level,dataStore.Value.Exp
end

local function updateOrdered(player: Player)
    local level,_ = LevelingAccess.Get(player)
    if level then
        LevelingOrdered.UpdatePlayerLevel(player, level)
    end
end

function LevelingAccess.Init()
    -- Update ordered datastore when a player joins
    for _,player in Players:GetPlayers() do
        updateOrdered(player)
    end
    Players.PlayerAdded:Connect(function(player)
        updateOrdered(player)
    end)    
end

return LevelingAccess