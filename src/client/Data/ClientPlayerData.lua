local ClientPlayerData = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- LocalPlayer --
local Player = Players.LocalPlayer

-- Folders --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Modules --
local BridgeNet2 = require(Packages.BridgeNet2)
local DataUtility = require(Shared.Data.DataUtility)
local Signal = require(Packages.signal)

-- Variables --
local PlayerDataUpdateBridge = BridgeNet2.ClientBridge("PlayerDataUpdate")
local ClientData = {
    Cash = 0;
    Level = 0;
    Exp = 0;
    Storage = {};
    PlacedItems = {};
}

-- Functions --
function ClientPlayerData.Get()
    return ClientData
end

function ClientPlayerData.GetKey(key)
    return ClientData[key]
end

-- Signals.
ClientPlayerData.DataStorageUpdate = Signal.new()
ClientPlayerData.CashUpdate = Signal.new()

function ClientPlayerData.Setup()
    PlayerDataUpdateBridge:Connect(function(data)
        print(data)
        local functions = {
            Storage = function(id,count)
                if not ClientData.Storage[id] then
                    ClientData.Storage[id] = count
                else
                    if count == -1 then
                        ClientData.Storage[id] = nil
                    else
                        ClientData.Storage[id] = count
                    end
                end
            end;
            Cash = function(count)
                ClientData.Cash = count
                ClientPlayerData.CashUpdate:Fire(count)
            end;
        }
        local type = DataUtility.GetTypeFromId(data.type)
        if type then
            if type == "Full" then
                functions["Cash"](data.arg1.Cash)
                for id,count in data.arg1.Storage do
                    functions["Storage"](id,count)
                end
            else
                functions[type](data.arg1,data.arg2)
            end
            ClientPlayerData.DataStorageUpdate:Fire(data)
        end
    end)
end

return ClientPlayerData