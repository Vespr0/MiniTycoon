local Dropper = {}
Dropper.__index = Dropper

local _Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService.Server
local Events = ReplicatedStorage.Events

local Drop = require(Server.Items.Droppers.Drop)
local PlayerDataAccess = require(Server.Data.PlayerDataAccess)

function Dropper.new(params)
    local dropper = setmetatable({}, Dropper)
    -- Propieties --
    dropper.plot = params.plot :: Folder
    dropper.owner = params.owner :: Player
    dropper.model = params.model :: Model

    dropper.localID = dropper.model:GetAttribute("LocalID")
    -- dropper.ownerUserID = dropper.owner.UserId

    dropper.dropperPart = dropper.model:WaitForChild("Dropper")
    dropper.dropPropieties = params.dropPropieties

    -- Client item replication
    Events.ItemReplication:FireClient(dropper.owner,"Dropper",{
        localID = dropper.model:GetAttribute("LocalID"),
        dropPropieties = params.dropPropieties,
        dropDelay = params.dropDelay
    })

    while dropper:exists() do
        task.wait(params.dropDelay)
        dropper:drop()
    end

    return dropper
end

function Dropper:exists()
    return self.model and self.model.Parent
end

function Dropper:drop()
    local drop = Drop.new(self.dropPropieties,{plot = self.plot,origin = self.dropperPart.Position})
    self.plot.Parts.Value += 1

    local partID = self.plot:GetAttribute("DropCounter") + 1
    drop.instance:SetAttribute("PartID",partID)
    self.plot:SetAttribute("DropCounter",partID)

    Events.DropReplication:FireAllClients(self.owner.UserId,self.localID,partID)

    local connection
    connection = drop.sold:Connect(function(sellMultiplier)
        PlayerDataAccess.AddCashToQueue(self.owner,drop:getValue()*sellMultiplier)
        connection:Disconnect()
    end)
end

return Dropper