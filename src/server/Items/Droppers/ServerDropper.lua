local Dropper = {}
Dropper.__index = Dropper

local _Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService.Server

local Drop = require(Server.Items.Droppers.Drop)
local PlayerDataAccess = require(Server.Data.PlayerDataAccess)

function Dropper.new(params)
    local dropper = setmetatable({}, Dropper)
    -- Propieties --
    dropper.plot = params.plot
    dropper.owner = params.owner
    dropper.model = params.model
    dropper.dropperPart = dropper.model:WaitForChild("Dropper")
    dropper.dropPropieties = params.dropPropieties
    while dropper:exists() do
        dropper:drop()
        task.wait(params.dropDelay)
    end
    return dropper
end

function Dropper:exists()
    return self.model and self.model.Parent
end

function Dropper:drop()
    local drop = Drop.new(self.dropPropieties,{plot = self.plot,origin = self.dropperPart.Position})
    local connection
    connection = drop.sold:Connect(function(sellMultiplier)
        warn("jeep")
        PlayerDataAccess.AddCashToQueue(self.owner,drop.value*sellMultiplier)
        connection:Disconnect()
    end)
end

return Dropper