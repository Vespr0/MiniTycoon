local LevelingOrdered = {}

-- Services --
local Players = game:GetService("Players")

-- Modules --
local PlayerOrderedDataManager = require(script.Parent.Parent.PlayerOrderedDataManager)

-- Constants --
LevelingOrdered.DatastoreName = "Level"

-- Functions --

function LevelingOrdered.UpdatePlayerLevel(...)
    local player, level = PlayerOrderedDataManager.GetParameters(...)
    if not (player and level) then return end
    
    PlayerOrderedDataManager.UpdatePlayerData(LevelingOrdered.DatastoreName, player, level)
end

function LevelingOrdered.Init()
    -- Initialize any setup logic if needed
end

return LevelingOrdered