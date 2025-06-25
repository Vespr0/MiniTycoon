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
local DataAccess = require(Server.Data.DataAccess)

-- Bridge.
local PlayerDataUpdateBridge = BridgeNet2.ServerBridge("PlayerDataUpdate")
PlayerDataUpdateBridge.Logging = false

-- Functions --
function PlayerDataReplication.SetupPlayer(player)
    repeat task.wait(.2) until player:GetAttribute("ClientLoaded")
    -- Send Full.
    local allData = DataAccess.GetFull(player)
    warn(allData)
	PlayerDataUpdateBridge:Fire(player,{type="Full",arg1=allData})

    --[[-- Cash.
    local CashTypeId = "Cash")
    dataFolder.Cash.Changed:Connect(function(value)
        PlayerDataUpdateBridge:Fire(player,{type=CashTypeId,arg1=value})
    end)]]
end

function PlayerDataReplication.Setup()
    local function sendItem(player,itemName,value)
        local data = {type="Storage",arg1=itemName,arg2=value}
        PlayerDataUpdateBridge:Fire(player,data)
    end
    local function sendConsumedItem(player,itemName)
        -- Send to the client to update it.
        local data = {type="Storage",arg1=itemName,arg2=-1}
        PlayerDataUpdateBridge:Fire(player,data)
    end
    DataAccess.PlayerDataChanged:Connect(function(player,type,arg1,arg2)
        --print(type,arg1,arg2)
        local functions = {
            ["Storage"] = function(player,itemName,count)
                if count > 0 then
                    sendItem(player,itemName,count)
                else
                    sendConsumedItem(player,itemName)
                end
            end;
            ["Cash"] = function(player,count)
                PlayerDataUpdateBridge:Fire(player,{type="Cash",arg1=count})
            end;
            ["Leveling"] = function(player,exp,level)
                PlayerDataUpdateBridge:Fire(player,{type="Leveling",arg1=exp,arg2=level})
            end;
            ["FirstPlayed"] = function(player,time)
                PlayerDataUpdateBridge:Fire(player,{type="FirstPlayed",arg1=time})
            end;
            ["LastPlayed"] = function(player,time)
                PlayerDataUpdateBridge:Fire(player,{type="LastPlayed",arg1=time})
            end;
            ["TimePlayed"] = function(player,time)
                PlayerDataUpdateBridge:Fire(player,{type="TimePlayed",arg1=time})
			end;
			["Plot"] = function(player,name,value)
				PlayerDataUpdateBridge:Fire(player,{type="Plot",arg1=name,arg2=value})
			end,
        }
        if not functions[type] then return end
        functions[type](player,arg1,arg2)
    end)
end

return PlayerDataReplication