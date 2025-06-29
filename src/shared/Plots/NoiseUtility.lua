local NoiseUtility = {}

local NOISE_SCALE = 20 

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
