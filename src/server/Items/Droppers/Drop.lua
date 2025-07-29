local Drop = {}
Drop.__index = Drop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage.Events
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local PartCache = require(Shared.Items.Droppers.PartCache)
local MainCache = PartCache.new(ReplicatedStorage.Drop,200)
local Signal = require(Packages.signal)
local DropUtil = require(Shared.Items.Droppers.DropUtil)
local ProductsInfo = require(Shared.Items.ProductsInfo)

function Drop.new(propieties,params)
    local drop = setmetatable({}, Drop)
    -- Propieties --
    drop.plot = params.plot
    drop.productType = params.productType
    drop.productQuantity = params.productQuantity
    drop.size = propieties.size and Vector3.one*propieties.size or Vector3.one/2
    drop.density = propieties.density or 1
    -- Instance --
    drop.ownerID = params.ownerID
    drop.localID = params.localID
    drop.partID = params.partID
    drop.instance = ReplicatedStorage.Drop:Clone() --PartCache.GetPart(MainCache) :: BasePart
    drop.instance.Parent = drop.plot.Drops
    drop.instance.Size = drop.size
    drop.instance.Anchored = false
    local heightBias = Vector3.yAxis* (drop.size.Y * (propieties.heightBias or 0))
    drop.instance:PivotTo(CFrame.new(params.origin+heightBias))
    drop.instance:SetNetworkOwner(nil)
	drop.instance.Transparency = --[[RunService:IsStudio() and 0.5 or]] 1
    drop.instance.Color = propieties.color or Color3.new(.4,0,.4) -- 404 color not found lol

    drop.instance:SetAttribute("PartID",drop.partID)
    -- Heartbeat loop --
    drop.onBelt = false
    drop.beltSpeed = 0
    drop.beltVector = Vector3.zero
    drop.beltVectorRaw = Vector3.zero
    drop.beltlessTime = 0
    -- List of upgraders the drop passed through.
    drop.boosts = {}
    drop.steps = 0

    drop.beltRaycasyParams = RaycastParams.new()
    drop.beltRaycasyParams.FilterType = Enum.RaycastFilterType.Include
    drop.beltRaycasyParams.FilterDescendantsInstances = {drop.plot.Items}

    drop.connection = RunService.Heartbeat:Connect(function(deltaTime)
        drop.steps += 1
        drop:step(deltaTime)
    end)

    -- Signals
    drop.sold = Signal.new()
    -- Loop
    drop:startLoop()    

    return drop
end

function Drop:destroy()
    self.connection:Disconnect()
    self.plot.Parts.Value -= 1
    task.wait(1/2)
    self.instance.Anchored = true
    self.instance.CanCollide = false
    task.wait(2)
    self.instance:Destroy()
    --MainCache:ReturnPart(self.instance)
end

function Drop:exists()
    return self.instance or self.instance.Parent 
end

function Drop:getValue()
    local baseValue = ProductsInfo.Products[self.productType].BaseSellValue
    local totalValue = baseValue * self.productQuantity
    
    for _,boost in pairs(self.boosts) do
        totalValue = DropUtil.CalculateBoost(totalValue, boost.type, boost.value)
    end
    return totalValue
end

function Drop:sell(sellMultiplier,forgeName)
    self.sold:Fire(sellMultiplier,forgeName)
    Events.DropReplication:FireAllClients(self.ownerID,self.localID,self.partID,true,forgeName,self.productType,self.productQuantity)
    self:destroy()
end

function Drop:rayCastDown(attribute)
    local height = self.instance.Size.Y
    local down = -(height/2 + 0.1)
    local size = self.instance.Size
    local vectors = {
        Vector3.yAxis*down, 
        Vector3.new(size.X/2,down,size.Z/2),
        Vector3.new(-size.X/2,down,size.Z/2),
        Vector3.new(size.X/2,down,-size.Z/2),
        Vector3.new(-size.X/2,down,-size.Z/2)
    }
    for _,vector in pairs(vectors) do
        local ray = workspace:Raycast(self.instance.Position,vector*2,self.beltRaycasyParams)
        if ray then
            local instance = ray.Instance
            local attributeValue = instance:GetAttribute(attribute)
            if attributeValue then
                return ray,attributeValue
            else
                continue
            end
        end
    end
    return nil
end

function Drop:getBelt()
    local raycast,speed = self:rayCastDown("Speed")
    --warn(raycast)
    if raycast and raycast.Instance then
        local slipperiness = raycast.Instance:GetAttribute("Slipperiness") or 0
        local biasedVector = self.beltVector * (3 + slipperiness)
        local newVector = raycast.Instance.CFrame.LookVector

        -- Calculate the dot product to find alignment
        local dotProduct = biasedVector:Dot(newVector)
        
        -- Smoothly adjust the speed based on alignment
        if dotProduct < 0 and self.beltVectorRaw ~= newVector then
            -- If opposite, reduce speed
            local newSpeed = speed * (1 + dotProduct)
            speed = (newSpeed+speed*4)/5
        end
        
        self.beltVector = (biasedVector + newVector).Unit
        self.beltVectorRaw = newVector
        self.beltSpeed = speed
        self.onBelt = true
        return
    end

    self.beltSpeed = math.max(self.beltSpeed - 0.01, 0)
    self.onBelt = false
end

function Drop:getForge()
    local raycast,sellMultiplier = self:rayCastDown("SellMultiplier")
    if raycast then
        self:sell(sellMultiplier,raycast.Instance.Parent:GetAttribute("ItemName"))
        return true
    end
    return false
end

function Drop:getUpgrader()
    local newBoosts = DropUtil.ProcessUpgraders(self.instance, self.plot, self.boosts)
    
    -- Apply new boosts
    for localID, boost in pairs(newBoosts) do
        self.boosts[localID] = boost
        -- Update current value
        -- self.instance:SetAttribute("CurrentValue", self:getValue())
    end
end

function Drop:startLoop()
    local sizeMagnitude = self.instance.Size.Magnitude
    local lastSecondPosition = self.instance.Position

    -- Update current value
    -- self.instance:SetAttribute("CurrentValue", self:getValue())

    task.spawn(function()
        while true do
            task.wait(1)
    
            if not self:exists() then break end
    
            local distanceTraveledLastSecond = (self.instance.Position - lastSecondPosition).Magnitude
            local sizeBias = (1+sizeMagnitude) -- Make sure it's not lower than one because of the division
            local goal = 1/sizeBias/self.density
            local traveledTooLittle = distanceTraveledLastSecond and distanceTraveledLastSecond < goal

            if traveledTooLittle then
                --print("Drop traveled "..distanceTraveledLastSecond.." had to travel more than "..goal)
                self.beltlessTime += 1
            else
                self.beltlessTime = 0
            end
    
            lastSecondPosition = self.instance.Position
        end
    end)    
end

function Drop:step(deltaTime)
    self:getBelt()
    self:getForge()
    if (self.steps%2 == 0) then
        self:getUpgrader()
    end

    -- if self.onBelt then
    --     self.beltlessTime = 0
    -- else
    --     --self.beltlessTime += deltaTime
    --     self.beltVector *= 0.95
    -- end

    -- Cap delta time
    -- deltaTime = math.min(deltaTime,.1)

    -- Calculate velocity
    local delta = 2 --(100*deltaTime)
    local sizePenaltyFactor = 1 + self.instance.Size.Magnitude/2
    
    local velocity = ((self.beltVector*self.beltSpeed)/self.density/sizePenaltyFactor) * delta
    self.instance.AssemblyLinearVelocity = velocity

    if self.beltlessTime > 3 then
        --print("Part expired")
        self:destroy()
    end
end

return Drop