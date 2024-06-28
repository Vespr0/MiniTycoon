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
    -- Session --
    Session = {
        FirstPlayed = 0;
        LastPlayed = 0;
        TimePlayed = 0;
    };
    -- Services --
    Services = {
        Offers = nil;
        OffersExpiration = nil;
    }
}

-- Functions --
function ClientPlayerData.Get()
    return ClientData
end

function ClientPlayerData.GetKey(key)
    return ClientData[key]
end

function ClientPlayerData.SetKey(key,value)
    ClientData[key] = value
end

-- Signals.
ClientPlayerData.DataStorageUpdate = Signal.new()
ClientPlayerData.CashUpdate = Signal.new()
ClientPlayerData.LevelingUpdate = Signal.new()

function ClientPlayerData.Read(data)
    local functions = {
        Storage = function(itemName,count)
            if not ClientData.Storage[itemName] then
                ClientData.Storage[itemName] = count
            else
                if count == -1 then
                    ClientData.Storage[itemName] = nil
                else
                    ClientData.Storage[itemName] = count
                end
            end
        end;
        Cash = function(count)
            ClientData.Cash = count
            ClientPlayerData.CashUpdate:Fire(count)
        end;
        Leveling = function(exp,level)
            ClientData.Exp = exp
            ClientData.Level = level
            ClientPlayerData.LevelingUpdate:Fire(exp,level)
        end;
        FirstPlayed = function(time)
            ClientData.Session.FirstPlayed = time
        end;
        LastPlayed = function(time)
            ClientData.Session.LastPlayed = time
        end;
        TimePlayed = function(time)
            ClientData.Session.TimePlayed = time
        end;
        OffersInfo = function(info)
            ClientData.Services.Offers = info.Offers
            ClientData.Services.OffersExpiration = info.Expiration
        end;
        -- Single --
        SingleOffer = function(offerID,offer)
            ClientData.Services.Offers[offerID] = offer
        end
    }
    local type = DataUtility.GetTypeFromId(data.type)
    if type then
        local arg1 = data.arg1
        local arg2 = data.arg2

        if type == "Full" then
            print(arg1)
            -- In this context, arg1 is the content.
            functions["Cash"](arg1.Cash)
            functions["Leveling"](arg1.Exp,arg1.Level)
            -- TODO: Maybe session could be sent as one array just like Leveling?
            functions["FirstPlayed"](arg1.Session.FirstPlayed)
            functions["LastPlayed"](arg1.Session.LastPlayed)
            functions["TimePlayed"](arg1.Session.TimePlayed)
            
            local services = arg1.Services
            functions["OffersInfo"]({Offers = services.Offers, Expiration = services.OffersExpiration})

            for itemName,count in arg1.Storage do
                functions["Storage"](itemName,count)
            end
        else
            functions[type](arg1,arg2)
        end
        ClientPlayerData.DataStorageUpdate:Fire(data)
    end
end

function ClientPlayerData.Setup()
    PlayerDataUpdateBridge:Connect(function(data)
        ClientPlayerData.Read(data)
    end)
end

return ClientPlayerData