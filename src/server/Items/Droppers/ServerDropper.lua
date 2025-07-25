local Dropper = {}
Dropper.__index = Dropper

local _Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server
local Events = ReplicatedStorage.Events

local Drop = require(Server.Items.Droppers.Drop)
local CashAccess = require(Server.Data.DataAccessModules.CashAccess)
local PlotUtility = require(Shared.Plots.PlotUtility)
local ProductsInfo = require(Shared.Items.ProductsInfo)

-- Constants
-- Tweak for more/less spread
local DROPPER_OFFSET_MULTIPLIER = 4

function Dropper.new(params)
    local dropper = setmetatable({}, Dropper)
    -- Propieties --
    dropper.config = params.config
    dropper.plot = params.plot :: Folder
    dropper.owner = params.owner :: Player
    dropper.model = params.model :: Model

    dropper.localID = dropper.model:GetAttribute("LocalID")
    -- dropper.ownerUserID = dropper.owner.UserId

    dropper.dropperPart = dropper.model:WaitForChild("Dropper")

    dropper:setup()

    -- Product info
    -- if not ProductsInfo.Products[params.productType] then
    --     error(`Product type '{params.productType}' not found in ProductsInfo.Products`)
    -- end

    return dropper
end

function Dropper:setup()
    -- Client item replication
    Events.ItemReplication:FireClient(self.owner,"Dropper",{
        localID = self.localID,
        config = self.config
    })

    -- Unique initial offset based on localID (stable but pseudo-random)
    local offset = ((math.sin(self.localID)+1)/2) * DROPPER_OFFSET_MULTIPLIER 
    -- Bias for longer drop delays
    local bias = self.config.DropDelay > 10 and 0 or self.config.DropDelay/10
    task.wait(self.config.DropDelay + offset + bias)

    -- Core loop
    while self:exists() do
        self:drop()
        task.wait(self.config.DropDelay)
    end
end

function Dropper:exists()
    return self.model and self.model.Parent
end

function Dropper:canDrop()
    -- Cannot drop if the part count has reached the plot's maximum
    local plotLevel = self.plot:GetAttribute("Level")
    local maxParts = PlotUtility.GetMaxPartsFromPlotLevel(plotLevel)
    if self.plot.Parts.Value >= maxParts then
        return false
    end

    return true
end

function Dropper:drop()
    if not self:canDrop() then return end

    local partID = self.plot:GetAttribute("DropCounter") + 1
    local ownerID = self.plot:GetAttribute("OwnerID")
    self.plot:SetAttribute("DropCounter",partID)
    self.plot.Parts.Value += 1

    local drop = Drop.new(self.config.DropPropieties,{
        plot = self.plot,
        origin = self.dropperPart.Position,
        localID = self.localID,
        ownerID = ownerID,
        partID = partID,
        productType = self.config.ProductType,
        productQuantity = self.config.ProductQuantity
    })

    Events.DropReplication:FireAllClients(self.owner.UserId,self.localID,partID,false,nil,self.productType,self.config.ProductQuantity)

    local connection
    connection = drop.sold:Connect(function(sellMultiplier,forgeName)
        CashAccess.AddCashToQueue(self.owner,drop:getValue()*sellMultiplier)
        connection:Disconnect()
    end)
end

return Dropper