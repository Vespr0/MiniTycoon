local NoiseUtility = {}

local NOISE_SCALE = 20 

-- Perlin Worms: Generates a set of points representing a "worm" path using Perlin noise
function NoiseUtility.generatePerlinWorm(startX: number, startY: number, seed: number, length: number, stepSize: number?, angleStep: number?): {{x: number, y: number}}
    local points = {}
    local x, y = startX, startY
    local currentAngle = 0
    local step = stepSize or 1
    local angleStepSize = angleStep or math.pi / 6 -- max angle change per step

    for i = 1, length do
        table.insert(points, {x = x, y = y})
        -- Use Perlin noise to determine the angle change
        local noise = math.noise(x * 0.1, y * 0.1, seed + i)
        local angleChange = noise * angleStepSize
        currentAngle = currentAngle + angleChange
        x = x + math.cos(currentAngle) * step
        y = y + math.sin(currentAngle) * step
    end
    return points
end

-- Generates a Perlin worm that's biased to pass through the center area
function NoiseUtility.generatePerlinWormThroughCenter(startX: number, startY: number, seed: number, length: number, stepSize: number?, angleStep: number?): {{x: number, y: number}}
    local points = {}
    local x, y = startX, startY
    local currentAngle = 0
    local step = stepSize or 1
    local angleStepSize = angleStep or math.pi / 6
    
    for i = 1, length do
        table.insert(points, {x = x, y = y})
        
        -- Calculate bias toward center (0, 0)
        local distanceToCenter = math.sqrt(x * x + y * y)
        local angleToCenter = math.atan2(-y, -x) -- Angle pointing toward center
        
        -- Use Perlin noise for natural variation
        local noise = math.noise(x * 0.1, y * 0.1, seed + i)
        local noiseAngleChange = noise * angleStepSize
        
        -- Apply center bias - stronger when farther from center
        local centerBias = math.min(distanceToCenter / 20, 1) * 0.3 -- Max 30% bias
        local biasedAngle = angleToCenter * centerBias + noiseAngleChange * (1 - centerBias)
        
        currentAngle = currentAngle + biasedAngle
        x = x + math.cos(currentAngle) * step
        y = y + math.sin(currentAngle) * step
    end
    
    return points
end

-- Basic octave summation for Perlin noise
function NoiseUtility.getNoiseValue(x: number, y: number, seed: number, scale: number?, octaves: number?, persistence: number?): number
    local oct = octaves or 3
    local pers = persistence or 0.5 
    local scal = scale or NOISE_SCALE + .01 -- + 0.01 to avoid math.noise bug 

    local amplitude = 1
    local frequency = 1
    local maxAmplitude = 0
    local noiseSum = 0

    for i = 1, oct do
        local nx = x / scal * frequency
        local ny = y / scal * frequency
        local n = math.noise(nx, ny, seed)
        noiseSum += n * amplitude

        maxAmplitude += amplitude
        amplitude *= pers
        frequency *= 2
    end

    -- Normalize to [-1, 1], then shift to [0, 1]
    local normalized = noiseSum / maxAmplitude
    normalized = math.clamp(normalized, -1, 1) + 0.5
    return normalized
end

return NoiseUtility
