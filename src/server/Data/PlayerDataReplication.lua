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
PlayerDataUpdateBridge.Logging = true

-- Functions --
function PlayerDataReplication.SetupPlayer(player)
    repeat task.wait(.2) until player:GetAttribute("ClientLoaded")
    -- Send Full.
    local FullTypeId = DataUtility.GetTypeId("Full")
    PlayerDataUpdateBridge:Fire(player,{type=FullTypeId,arg1=PlayerDataAccess.GetFull(player)})

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

    local function sendItem(player,itemID,value)
        local data = {type=StorageTypeId,arg1=itemID,arg2=value}
        PlayerDataUpdateBridge:Fire(player,data)
    end
    local function sendConsumedItem(player,itemID)
        -- Send to the client to update it.
        local data = {type=StorageTypeId,arg1=itemID,arg2=-1}
        PlayerDataUpdateBridge:Fire(player,data)
    end
    PlayerDataAccess.PlayerDataChanged:Connect(function(player,type,arg1,arg2)
        print(type,arg1,arg2)
        local functions = {
            [DataUtility.GetTypeId("Storage")] = function(player,itemID,count)
                if count > 0 then
                    sendItem(player,itemID,count)
                else
                    sendConsumedItem(player,itemID)
                end
            end;
            [DataUtility.GetTypeId("Cash")] = function(player,count)
                PlayerDataUpdateBridge:Fire(player,{type=CashTypeId,arg1=count})
            end;
        }
        if not functions[type] then return end
        functions[type](player,arg1,arg2)
    end)
end

return PlayerDataReplication