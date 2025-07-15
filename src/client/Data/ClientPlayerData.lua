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

ClientPlayerData.Data = {
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
	-- Plot --
	Plot = {
		PlotLevel = 1;
	};
    -- Services --
    Services = {
        Offers = nil;
        OffersExpiration = nil;
	}
	
}

-- Signals.
ClientPlayerData.DataUpdate = Signal.new()
-- Cash
ClientPlayerData.CashUpdate = Signal.new()
-- Leveling
ClientPlayerData.ExpUpdate = Signal.new()
ClientPlayerData.LevelUpdate = Signal.new()
-- Storage
ClientPlayerData.StorageUpdate = Signal.new()

ClientPlayerData.DataSynched = false
ClientPlayerData.DataSynchedEvent = Signal.new()

function ClientPlayerData.Read(data)
    local functions = {
        Storage = function(itemName,count)
			if not ClientPlayerData.Data.Storage[itemName] then
				ClientPlayerData.Data.Storage[itemName] = count
            else
                if count == -1 then
					ClientPlayerData.Data.Storage[itemName] = nil
                else
					ClientPlayerData.Data.Storage[itemName] = count
                end
            end
            ClientPlayerData.StorageUpdate:Fire(itemName,count)
        end;
        Cash = function(count)
			ClientPlayerData.Data.Cash = count
            ClientPlayerData.CashUpdate:Fire(count)
        end;
        Leveling = function(exp,level)
			ClientPlayerData.Data.Exp = exp
            if level ~= ClientPlayerData.Data.Level then
                ClientPlayerData.LevelUpdate:Fire(level)
            end
			ClientPlayerData.Data.Level = level
            ClientPlayerData.ExpUpdate:Fire(exp,level)
        end;
        FirstPlayed = function(time)
			ClientPlayerData.Data.Session.FirstPlayed = time
        end;
        LastPlayed = function(time)
			ClientPlayerData.Data.Session.LastPlayed = time
        end;
        TimePlayed = function(time)
			ClientPlayerData.Data.Session.TimePlayed = time
        end;
        OffersInfo = function(info)
			ClientPlayerData.Data.Services.Offers = info.Offers
			ClientPlayerData.Data.Services.OffersExpiration = info.Expiration
        end;
        -- Single --
        SingleOffer = function(offerID,offer)
			ClientPlayerData.Data.Services.Offers[offerID] = offer
		end;
		-- Plot
		Plot = function(name,value)
			ClientPlayerData.Data.Plot[name] = value
		end;
    }
	if data.type then
        local arg1 = data.arg1
        local arg2 = data.arg2

		if data.type == "Full" then
            print(arg1)
            -- In this context, arg1 is the content.
            functions["Cash"](arg1.Cash)
            functions["Leveling"](arg1.Exp,arg1.Level)
            -- TODO: Maybe session could be sent as one array just like Leveling?
            functions["FirstPlayed"](arg1.Session.FirstPlayed)
            functions["LastPlayed"](arg1.Session.LastPlayed)
			functions["TimePlayed"](arg1.Session.TimePlayed)
			
			for name,value in arg1.Plot do
				functions["Plot"](name,value)
			end
            
            local services = arg1.Services
            functions["OffersInfo"]({Offers = services.Offers, Expiration = services.OffersExpiration})

            for itemName,count in arg1.Storage do
                functions["Storage"](itemName,count)
            end

            if not ClientPlayerData.DataSynched then
                ClientPlayerData.DataSynchedEvent:Fire()
            end
            ClientPlayerData.DataSynched = true
        else
			functions[data.type](arg1,arg2)
        end
        ClientPlayerData.DataUpdate:Fire(data)
    end
end

function ClientPlayerData.Setup()
    PlayerDataUpdateBridge:Connect(function(data)
        ClientPlayerData.Read(data)
    end)
end

return ClientPlayerData