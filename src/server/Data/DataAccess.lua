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

function DataAccess.WipePlayerData(userId)
	if typeof(userId) ~= "number" and typeof(userId) ~= "string" then
		warn("DataAccess.WipePlayerData: Invalid userId type, expected number or string")
		return false
	end
	
	-- Convert to string for consistency
	local userIdStr = tostring(userId)
	
	-- Find the datastore
	local dataStore = DataAccess.AccessDataStore(nil, userIdStr)
	if not dataStore then
		warn("DataAccess.WipePlayerData: Could not access datastore for userId " .. userIdStr)
		return false
	end
	
	-- Get the data template from PlayerDataStore
	local PlayerDataStore = require(script.Parent.PlayerDataStore)
	local dataTemplate = {
		-- Basic Data --
		Level = 1;
		Exp = 0;
		Cash = 0;
		-- Items --
		Storage = {};
		PlacedItems = {};
		-- Plot --
		Plot = {
			PlotLevel = 1;
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
		};
		Tutorial = {
			TutorialFinished = false;
			SavedTutorialPhase = 1
		};
		-- Onboarding steps tracking --
		Onboarding = {}
	}
	
	-- Reset to template
	dataStore.Value = dataTemplate
	
	-- If player is online, update their client data
	local player = Players:GetPlayerByUserId(tonumber(userIdStr))
	if player then
		-- Fire full data update to client
		DataAccess.PlayerDataChanged:Fire(player, "Full", dataStore.Value)
	end
	
	warn("DataAccess.WipePlayerData: Successfully wiped data for userId " .. userIdStr)
	return true
end

-- Setup --
function DataAccess.Setup()
    for _,dataAccessModule in pairs(DataAccessModules:GetChildren()) do
        if dataAccessModule:IsA("ModuleScript") then
            local module = require(dataAccessModule)
            if module.Init then
                module.Init()
            end
        end
    end
end

return DataAccess