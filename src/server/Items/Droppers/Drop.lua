local Drop = {}
Drop.__index = Drop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PartCache = require(ReplicatedStorage.Shared.Items.Droppers.PartCache)
local MainCache = PartCache.new(ReplicatedStorage.Drop,200)
local Signal = require(ReplicatedStorage.Packages.signal)

function Drop.new(propieties,params)
    local drop = setmetatable({}, Drop)
    -- Propieties --
    drop.plot = params.plot
    drop.value = propieties.value or 1
    drop.size = propieties.size and Vector3.one*propieties.size or Vector3.one/2
    drop.color = propieties.color or Color3.new(1,1,1)
    drop.density = propieties.density or 1
    -- Instance --
    drop.instance = PartCache.GetPart(MainCache) :: BasePart
    drop.instance.Parent = drop.plot.Drops
    drop.instance.Size = drop.size
    drop.instance.Anchored = false
    drop.instance:PivotTo(CFrame.new(params.origin))
    drop.instance:SetNetworkOwner(nil)
    -- Heartbeat loop --
    drop.onBelt = false
    drop.beltSpeed = 0
    drop.beltVector = nil
    drop.beltlessTime = 0
    -- List of upgraders the drop passed through.
    drop.upgraders = {}
    drop.connection = RunService.Heartbeat:Connect(function()
        drop:step()
    end)
    -- Signals
    drop.sold = Signal.new()
    return drop
end

function Drop:sell(sellMultiplier)
    self.sold:Fire(sellMultiplier)
    self:destroy()
end

function Drop:destroy()
    self.connection:Disconnect()
    MainCache:ReturnPart(self.instance)
end

function Drop:rayCastDown()
    local height = self.instance.Size.Y
    return workspace:Raycast(self.instance.Position,-Vector3.yAxis*(height/2+1/4))
end

function Drop:getBelt()
    local raycast = self:rayCastDown()
    if raycast then
        local speed = raycast.Instance:GetAttribute("Speed")
        if speed then
            self.beltVector = raycast.Instance.CFrame.LookVector
            self.beltSpeed = speed
            self.onBelt = true
            return
        end
    end
    self.onBelt = false
end

function Drop:getForge()
    local raycast = self:rayCastDown()
    if raycast then
        local sellMultiplier = raycast.Instance:GetAttribute("SellMultiplier")
        if sellMultiplier then
            self:sell(sellMultiplier)
            return
        end
    end
end

function Drop:step()
    self:getBelt()
    self:getForge()
    if self.onBelt then
        self.beltlessTime = 0
        self.instance.AssemblyLinearVelocity = self.beltVector*self.beltSpeed*5
    else
        self.beltlessTime += 1
    end
    if self.beltlessTime > 100 then
        self:destroy()
    end
end

return Drop