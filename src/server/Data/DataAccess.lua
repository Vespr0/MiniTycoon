local DataAccess = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server
local Packages = ReplicatedStorage.Packages
local DataAccessModules = script.Parent.DataAccessModules

-- Modules --
local DataStoreModule = require(Packages.suphisdatastoremodule)
local DataUtility = require(Shared.Data.DataUtility)
local Signal = require(Packages.signal)

-- Signals
DataAccess.PlayerDataChanged = Signal.new()

-- Constants --
DataAccess.Errors = {
    accessAttemptFailedNil = "📋 Trying to access datastore, but it is nil.";
    accessAttemptFailedClosed = "📋 Trying to access datastore, but it is closed.";
    accessFailed = "📋 Failed to access datastore.";
    invalidParameters = "📋 Invalid parameter, %q is nil";
}
local ERRORS = DataAccess.Errors

-- Variables --
DataAccess.DataUtility = DataUtility

-- Local Functions --

local function isDataStoreAccessible(dataStore)
    if dataStore == nil then
        return false,ERRORS.accessAttemptFailedNil
    end
    -- Make sure the session is open or the value will never get saved
    if dataStore.State ~= true then 
        return false,ERRORS.accessAttemptFailedClosed
    end
    return true
end

-- Functions --

function DataAccess.GetParameters(...)
    local args = {...}
    local returnedArgs = {}
    -- The first one is always the DataAccess table.
    
    for i,v in args do
        --if typeof(v) ~= "table" then
            returnedArgs[i] = v;
        --end
        if v == nil then 
            error(string.format(ERRORS.invalidParameters,i)); 
        end
    end
    if #returnedArgs > 0 then
        return table.unpack(returnedArgs)
    end

    return nil
end

function DataAccess.AccessDataStore(name,key,r)
    r = r or 5
    if r <= 0 then 
        error(ERRORS.accessFailed.."#"..key);    
    return end
    local dataStore = DataStoreModule.find(name or DataUtility.GetDataScope("Player"),key)
    local success,error = isDataStoreAccessible(dataStore)
    if not success then
        print(error.." ...Retrying...")
        task.wait(1)
        return DataAccess.AccessDataStore(name,key,r-1)
    end
    return dataStore
end

function DataAccess.GetFull(...)
	local player = DataAccess.GetParameters(...)
	if not player then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    return dataStore.Value
end

-- Setup --
function DataAccess.Setup()
    for _,dataAccessModule in pairs(DataAccessModules:GetChildren()) do
        if dataAccessModule:IsA("ModuleScript") then
            local module = require(dataAccessModule)
            if module.Setup then
                module.Setup()
            end
        end
    end
end

return DataAccess