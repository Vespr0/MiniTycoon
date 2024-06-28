local Dropper = {}
Dropper.__index = Dropper

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local Events = ReplicatedStorage.Events

local AssetsDealer = require(Shared.AssetsDealer)
local PlotUtility = require(Shared.Plots.PlotUtility)
local FXManager = require(script.Parent.Parent.Parent.FX.FXManager)
local ClientDrop = require(script.Parent.ClientDrop)

local LocalPlayer = Players.LocalPlayer

function Dropper.new(params)
    local dropper = setmetatable({}, Dropper)
    -- Drop Propieties --
    dropper.model = params.model
    dropper.localID = dropper.model:GetAttribute("LocalID")
    dropper.signal = params.signal
    dropper.dropPropieties = params.dropPropieties
    dropper.dropDelay = params.dropDelay
    dropper.Plot = params.plot
    
    -- Parts --
    dropper.dropperPart = dropper.model:WaitForChild("Dropper")
    dropper.dropperPartAttachment = Instance.new("Attachment")
    dropper.dropperPartAttachment.Parent = dropper.dropperPart
    dropper.dropperPartAttachment.Name = "DropperAttachment"

    -- Drop --
    local connection
    connection = Events.DropReplication.OnClientEvent:Connect(function(r_ownerID,r_localID,r_partID,sold,forgeName)
        if sold then return end
        if r_ownerID ~= dropper.Plot:GetAttribute("OwnerID") then return end

        -- TODO: checking Local ID may be useless
        local sameItem = r_localID == dropper.model:GetAttribute("LocalID")
        if not sameItem then return end

        local part = nil
        local attempts = 0
        repeat 
            if attempts > 0 then
                RunService.RenderStepped:Wait()
            end
            part = PlotUtility.GetPart(dropper.Plot,r_partID)
            attempts += 1
        until part or attempts > 5

        if part then
            dropper:drop(part,r_partID)
        end
    end)

    while true do
        task.wait(.1)

        if not dropper:exists() then
            connection:Disconnect()
        end
    end

    return dropper
end

function Dropper:exists()
    return self.model and self.model.Parent
end

function Dropper:drop(part,partID)
    -- Poof effect
    TweenService:Create(self.dropperPart,TweenInfo.new(.3,Enum.EasingStyle.Bounce,Enum.EasingDirection.In,0,true),{
        Size = self.dropperPart.Size * 1.2
    }):Play()
    FXManager.Poof({
        attachment = self.dropperPartAttachment;
        particle = self.dropPropieties.particle;
        sound = self.dropPropieties.sound;
    })

    self.clientDrop = ClientDrop.new(self.dropPropieties,{
        instance = part,
        plot = self.Plot,
        localID = self.localID,
        partID = partID
    })
end

return Dropper