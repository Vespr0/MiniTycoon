local Drop = {}
Drop.__index = Drop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PartCache = require(ReplicatedStorage.Shared.Items.Droppers.PartCache)
local MainCache = PartCache.new(ReplicatedStorage.Drop,200)
local Signal = require(ReplicatedStorage.Packages.signal)
local DropUtil = require(script.Parent.DropUtil)

function Drop.new(propieties,params)
    local drop = setmetatable({}, Drop)
    -- Propieties --
    drop.plot = params.plot
    drop.startingValue = propieties.value or 1
    drop.size = propieties.size and Vector3.one*propieties.size or Vector3.one/2
    drop.density = propieties.density or 1
    -- Instance --
    drop.instance = PartCache.GetPart(MainCache) :: BasePart
    drop.instance.Parent = drop.plot.Drops
    drop.instance.Size = drop.size
    drop.instance.Anchored = false
    local heightBias = Vector3.yAxis* (drop.size.Y * (propieties.heightBias or 0))
    drop.instance:PivotTo(CFrame.new(params.origin+heightBias))
    drop.instance:SetNetworkOwner(nil)
    drop.instance.Transparency = 1
    drop.instance.Color = propieties.color or Color3.new(.4,0,.4) -- 404 color not found lol
    -- Heartbeat loop --
    drop.onBelt = false
    drop.beltSpeed = 0
    drop.beltVector = Vector3.zero
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
    task.wait(1)
    MainCache:ReturnPart(self.instance)
end

function Drop:exists()
    return self.instance or self.instance.Parent 
end

function Drop:getValue()
    local value = self.startingValue
    for _,boost in pairs(self.boosts) do
        value = DropUtil.CalculateBoost(value, boost.type, boost.value)
    end
    return value
end

function Drop:sell(sellMultiplier)
    warn("cha ching")
    self.sold:Fire(sellMultiplier)
    self:destroy()
end

function Drop:rayCastDown()
    local height = self.instance.Size.Y
    return workspace:Raycast(self.instance.Position,-Vector3.yAxis*(height/2+1/2),self.beltRaycasyParams)
end

function Drop:getBelt()
    local raycast = self:rayCastDown()

    if raycast and raycast.Instance then
        local speed = raycast.Instance:GetAttribute("Speed")
        if speed then
            local slipperiness = raycast.Instance:GetAttribute("Slipperiness") or 0
            self.beltVector = (self.beltVector*(5+slipperiness) + raycast.Instance.CFrame.LookVector).Unit
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
            warn(raycast.Instance.Name,raycast.Instance.Parent.Name,sellMultiplier)
            self:sell(sellMultiplier)
            return
        end
    end
end

function Drop:getDistanceToPart(part)
    return (self.instance.Position - part.Position).Magnitude
end

-- Check if the upgraders are close enough to afford calculating complex collisions.
function Drop:getPotentialUpgraders()
    local items = self.plot.Items

    local closeUpgraders = {}
    for _,item in pairs(items:GetChildren()) do
        if item:GetAttribute("ItemType") == "Upgrader" then
            local localID = item:GetAttribute("LocalID")
            if closeUpgraders[localID] then
                continue
            end
            if self.boosts[localID] then
                continue
            end

            local upgrader = item:FindFirstChild("Upgrader")
            if upgrader then
                local dist = self:getDistanceToPart(upgrader)
                local upgraderBiggestAxis = math.max(upgrader.Size.X,upgrader.Size.Y,upgrader.Size.Z)
                if dist > upgraderBiggestAxis then
                    continue
                end
                --warn("Addded to the list of potential upgraders",localID,upgrader)
                closeUpgraders[localID] = upgrader
                -- if closest == nil or self:getDistanceToPart(upgrader) < self:getDistanceToPart(closest) then
                --     closest = upgrader
                -- end
            else
                warn("Missing upgrader part in upgrader item: "..item.Name)
            end
        end
    end

    return closeUpgraders
end

function Drop:getUpgrader()
    local upgraders = self:getPotentialUpgraders()
    if next(upgraders) then
        for localID,upgrader in pairs(upgraders) do
            local overlapParams = OverlapParams.new()
            overlapParams.FilterType = Enum.RaycastFilterType.Include
            overlapParams.FilterDescendantsInstances = {self.instance}
            local results = workspace:GetPartBoundsInBox(upgrader.CFrame,upgrader.Size,overlapParams)

            if results and results[1] == self.instance then
                local boostType = upgrader:GetAttribute("BoostType")
                local boostValue = upgrader:GetAttribute("BoostValue")
                self.boosts[localID] = {type = boostType,value = boostValue}
            end
        end
    end 
end

function Drop:startLoop()
    local sizeMagnitude = self.instance.Size.Magnitude
    local lastSecondPosition = self.instance.Position

    task.spawn(function()
        while true do
            task.wait(1)
    
            if not self:exists() then break end
    
            local distanceTraveledLastSecond = (self.instance.Position - lastSecondPosition).Magnitude
            local sizeBias = (1+sizeMagnitude) -- Make sure it's not lower than one because of the division
            local densityBias = (1/self.density)/2
            local goal = 1/sizeBias/densityBias
            local traveledTooLittle = distanceTraveledLastSecond and distanceTraveledLastSecond < goal

            warn(goal)
            if traveledTooLittle then
                warn("Traveled "..distanceTraveledLastSecond.." had to travel more than "..goal)
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

    -- Calculate velocity
    local delta = (100*deltaTime)
    local sizePenaltyFactor = 1 + self.instance.Size.Magnitude/2
    local velocity = ((self.beltVector*self.beltSpeed)/self.density/sizePenaltyFactor) * delta
    self.instance.AssemblyLinearVelocity = velocity

    if self.beltlessTime > 3 then
        warn("Part expired")
        self:destroy()
    end
end

return Drop