--[[
	WindSimulation Module
	
	Simple dynamic wind simulation that directly modifies GlobalWind.
]]

local RunService = game:GetService("RunService")

local WindSimulation = {}

-- Configuration
local UPDATE_INTERVAL = 0.1
local CHANGE_SPEED = 0.2
local MIN_WIND_SPEED = 3
local MAX_WIND_SPEED = 20
local MAX_DIRECTION_CHANGE = math.rad(30) -- 30 degrees
local MAX_INTENSITY_CHANGE = 3
local TURBULENCE = 0.1

-- State
local lastUpdate = 0
local directionTimer = 0
local intensityTimer = 0
local connection = nil

local function updateWind(deltaTime)
	local currentWind = workspace.GlobalWind
	local currentDirection = currentWind.Unit
	local currentIntensity = currentWind.Magnitude
	
	directionTimer = directionTimer + deltaTime
	intensityTimer = intensityTimer + deltaTime
	
	local targetDirection = currentDirection
	local targetIntensity = currentIntensity
	
	-- Change direction every 8-20 seconds
	if directionTimer >= math.random(8, 20) then
		local currentAngle = math.atan2(currentDirection.Z, currentDirection.X)
		local angleChange = (math.random() - 0.5) * 2 * MAX_DIRECTION_CHANGE
		local newAngle = currentAngle + angleChange
		
		local verticalChange = (math.random() - 0.5) * 0.1
		local newVertical = math.clamp(currentDirection.Y + verticalChange, -0.3, 0.3)
		
		targetDirection = Vector3.new(math.cos(newAngle), newVertical, math.sin(newAngle)).Unit
		directionTimer = 0
	end
	
	-- Change intensity every 6-12 seconds
	if intensityTimer >= math.random(6, 12) then
		local intensityChange = (math.random() - 0.5) * 2 * MAX_INTENSITY_CHANGE
		targetIntensity = math.clamp(currentIntensity + intensityChange, MIN_WIND_SPEED, MAX_WIND_SPEED)
		intensityTimer = 0
	end
	
	-- Interpolate to targets
	local lerpFactor = math.min(CHANGE_SPEED * deltaTime, 1)
	local newDirection = currentDirection:lerp(targetDirection, lerpFactor).Unit
	local newIntensity = currentIntensity + (targetIntensity - currentIntensity) * lerpFactor
	
	-- Apply turbulence
	local time = tick()
	local turbulence = Vector3.new(
		(math.sin(time * 0.7) + math.sin(time * 1.3)) * TURBULENCE,
		math.sin(time * 0.5) * TURBULENCE * 0.5,
		(math.cos(time * 0.9) + math.cos(time * 1.1)) * TURBULENCE
	)
	
	local finalDirection = (newDirection + turbulence).Unit
	workspace.GlobalWind = finalDirection * newIntensity
end

local function update()
	local currentTime = tick()
	local deltaTime = currentTime - lastUpdate
	
	if deltaTime < UPDATE_INTERVAL then
		return
	end
	
	lastUpdate = currentTime
	updateWind(deltaTime)
end

function WindSimulation.Start()
	WindSimulation.Stop()
	-- Initialize GlobalWind if it's zero
	if workspace.GlobalWind.Magnitude == 0 then
		workspace.GlobalWind = Vector3.new(1, 0, 0) * 10
	end
	connection = RunService.Heartbeat:Connect(update)
end

function WindSimulation.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

function WindSimulation.SetWindSpeed(minSpeed, maxSpeed)
	MIN_WIND_SPEED = minSpeed or MIN_WIND_SPEED
	MAX_WIND_SPEED = maxSpeed or MAX_WIND_SPEED
end

function WindSimulation.SetTurbulence(factor)
	TURBULENCE = math.clamp(factor or TURBULENCE, 0, 1)
end

return WindSimulation