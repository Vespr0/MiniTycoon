local Tweener = {}
Tweener.__index = Tweener

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Curves = ReplicatedStorage.Curves

function Tweener.new(target, goals, duration, curve, reverse)
    local self = setmetatable({}, Tweener)
    self.target = target
    self.goals = goals
    self.duration = duration
    self.curve = require(Curves[curve])
    self.reverse = reverse or false
    self.startTime = tick()
    self.connection = nil
    self.startValues = {}
    
    -- Store the initial values for each property
    for property, goal in pairs(goals) do
        self.startValues[property] = target[property]
    end

    return self
end

-- Starts the tween
function Tweener:Start()
    self.startTime = tick()
    self.connection = game:GetService("RunService").Heartbeat:Connect(function()
        self:Update()
    end)
end

-- Updates the tween on each heartbeat
function Tweener:Update()
    local elapsedTime = tick() - self.startTime
    local progress = elapsedTime / self.duration

    if progress >= 1 then
        progress = 1
        self:Complete()
    end

    -- Adjust progress for reverse option
    if self.reverse then
        progress = 1 - progress
    end

    for property, goal in pairs(self.goals) do
        local startValue = self.startValues[property]
        self.target[property] = startValue:Lerp(goal, self.curve:Get(progress))
    end
end

function Tweener:Complete()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    -- Ensure the target properties are set to the exact goal values
    for property, goal in pairs(self.goals) do
        if self.reverse then
            self.target[property] = self.startValues[property]
        else
            self.target[property] = goal
        end
    end
end

function Tweener:Cancel()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

return Tweener
