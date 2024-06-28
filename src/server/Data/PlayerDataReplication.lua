local PlayerDataReplication = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server
local Packages = ReplicatedStorage.Packages

-- Modules --
local DataUtility = require(Shared.Data.DataUtility)
local _Trove = require(Packages.trove)
local BridgeNet2 = require(Packages.BridgeNet2)
local Signal = require(Packages.signal)
local PlayerDataAccess = require(Server.Data.PlayerDataAccess)

-- Bridge.
local PlayerDataUpdateBridge = BridgeNet2.ServerBridge("PlayerDataUpdate")
PlayerDataUpdateBridge.Logging = false

-- Functions --
function PlayerDataReplication.SetupPlayer(player)
    repeat task.wait(.2) until player:GetAttribute("ClientLoaded")
    -- Send Full.
    local fullTypeId = DataUtility.GetTypeId("Full")
    local allData = PlayerDataAccess.GetFull(player)
    warn(allData)
    PlayerDataUpdateBridge:Fire(player,{type=fullTypeId,arg1=allData})

    --[[-- Cash.
    local CashTypeId = DataUtility.GetTypeId("Cash")
    dataFolder.Cash.Changed:Connect(function(value)
        PlayerDataUpdateBridge:Fire(player,{type=CashTypeId,arg1=value})
    end)]]
end

function PlayerDataReplication.Setup()
    -- Data Types.
    local StorageTypeId = DataUtility.GetTypeId("Storage")
    local CashTypeId = DataUtility.GetTypeId("Cash")
    local LevelingTypeId = DataUtility.GetTypeId("Leveling")

    local function sendItem(player,itemName,value)
        local data = {type=StorageTypeId,arg1=itemName,arg2=value}
        PlayerDataUpdateBridge:Fire(player,data)
    end
    local function sendConsumedItem(player,itemName)
        -- Send to the client to update it.
        local data = {type=StorageTypeId,arg1=itemName,arg2=-1}
        PlayerDataUpdateBridge:Fire(player,data)
    end
    PlayerDataAccess.PlayerDataChanged:Connect(function(player,type,arg1,arg2)
        --print(type,arg1,arg2)
        local functions = {
            [DataUtility.GetTypeId("Storage")] = function(player,itemName,count)
                if count > 0 then
                    sendItem(player,itemName,count)
                else
                    sendConsumedItem(player,itemName)
                end
            end;
            [DataUtility.GetTypeId("Cash")] = function(player,count)
                PlayerDataUpdateBridge:Fire(player,{type=CashTypeId,arg1=count})
            end;
            [DataUtility.GetTypeId("Leveling")] = function(player,exp,level)
                PlayerDataUpdateBridge:Fire(player,{type=LevelingTypeId,arg1=exp,arg2=level})
            end;
            [DataUtility.GetTypeId("FirstPlayed")] = function(player,time)
                PlayerDataUpdateBridge:Fire(player,{type=DataUtility.GetTypeId("FirstPlayed"),arg1=time})
            end;
            [DataUtility.GetTypeId("LastPlayed")] = function(player,time)
                PlayerDataUpdateBridge:Fire(player,{type=DataUtility.GetTypeId("LastPlayed"),arg1=time})
            end;
            [DataUtility.GetTypeId("TimePlayed")] = function(player,time)
                PlayerDataUpdateBridge:Fire(player,{type=DataUtility.GetTypeId("TimePlayed"),arg1=time})
            end;
        }
        if not functions[type] then return end
        functions[type](player,arg1,arg2)
    end)
end

return PlayerDataReplication