local SessionAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local PlayerDataAccess = require(script.Parent.Parent.PlayerDataAccess)
local DataUtility = PlayerDataAccess.DataUtility

local function setSessionVariable(player,variable,value)
    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    dataStore.Value.Session[variable] = value or os.time()
end

local function hasPlayerPlayedBefore(player)
    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    local firstPlayed = dataStore.Value.Session["FirstPlayed"]
    return not (firstPlayed == nil or firstPlayed == 0)
end

function SessionAccess.SetFirstPlayed(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    setSessionVariable(player,"FirstPlayed")
    warn(player.UserId.." first played: "..os.date("%c"))

    -- Update
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("FirstPlayed"),os.time())
end

function SessionAccess.SetLastPlayed(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    setSessionVariable(player,"LastPlayed")
    warn(player.UserId.." last played: "..os.date("%c"))

    -- Update
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("LastPlayed"),os.time())
end

function SessionAccess.UpdateTotalPlayTime(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    local addedPlayTime = os.time() - dataStore.Value.Session["LastPlayed"] 

    dataStore.Value.Session["TimePlayed"] += addedPlayTime
    warn("Total Play Time: "..dataStore.Value.Session["TimePlayed"].. ". It was incremented by "..addedPlayTime)

    -- Update
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("TimePlayed"),addedPlayTime)
end

function SessionAccess.Setup()
    Players.PlayerAdded:Connect(function(player)
        if not hasPlayerPlayedBefore(player) then
            SessionAccess.SetFirstPlayed(player)
        end
        SessionAccess.SetLastPlayed(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        SessionAccess.UpdateTotalPlayTime(player)
    end)
end

return SessionAccess