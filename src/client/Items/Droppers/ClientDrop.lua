local ClientDrop = {}
ClientDrop.__index = ClientDrop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local AssetsDealer = require(Shared.AssetsDealer)

function ClientDrop.new(properties,params)
    local drop = setmetatable({}, ClientDrop)
    -- Instance --
    drop.instance = params.Instance
    drop.instance.Transparency = 1
    -- Mesh --
    drop.mesh = AssetsDealer.GetMesh(properties.mesh)
    drop.mesh.Parent = workspace
    drop.mesh.Name = "Mesh"
    drop.mesh.Size = Vector3.one/100
    drop.mesh.Color = drop.instance.Color

    drop.mesh.CanCollide = false
    drop.mesh.CanQuery = false
    drop.mesh.CanTouch = false
    drop.mesh.Massless = true 
    drop.mesh.Anchored = true

    drop.tweenDelay = 0.1

    drop.mesh.CFrame = drop.instance.CFrame

    drop:grow()
    drop.connection = RunService.Heartbeat:Connect(function()
        local partExists = drop.instance and drop.instance.Parent
        local meshExists = drop.mesh and drop.mesh.Parent
        if partExists and meshExists then
            drop:step()
        else
            drop:destroy(drop.instance:GetAttribute("Sold"))
        end
    end)

    return drop
end

function ClientDrop:destroy(sold: boolean)
    self.connection:Disconnect()
    self.mesh:Destroy()
end

function ClientDrop:grow()
    TweenService:Create(self.mesh,TweenInfo.new(math.min(.6,self.instance.Size.Magnitude),Enum.EasingStyle.Sine),{
        Size = self.instance.Size
    }):Play()
end

function ClientDrop:step()
    TweenService:Create(self.mesh,TweenInfo.new(self.tweenDelay,Enum.EasingStyle.Linear),{
        CFrame = self.instance.CFrame    
    }):Play()
end

return ClientDrop