local TilingUtility = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NoiseUtility = require(ReplicatedStorage.Shared.Plots.NoiseUtility)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)

export type Tile = {
    assetName: string,
    noiseValue: number
}

local NOISE_ASSET_RANGES = {
    { threshold = 0.7, assetName = "Grass" },
    { threshold = 0.5, assetName = "Sand" },
    { threshold = -math.huge, assetName = "Water" }, -- fallback
}

local RIVERS_COUNT = 3 -- Number of rivers to generate

local function calculateCenterBias(distanceFromCenter: number, tilesPerSide: number): number
    return math.atan(1 - (distanceFromCenter / (tilesPerSide / 2)))
end

local function isNearRiver(x, y, riverPoints, radius)
    for _, point in riverPoints do
        local dx = x - point.x
        local dy = y - point.y
        if (dx*dx + dy*dy) <= radius*radius then
            return true
        end
    end
    return false
end

function TilingUtility.GetActualPlotWidth(plotLevel: number): number
    return plotLevel * 20 -- Assuming each plot level increases the width by 20 units
end

function TilingUtility.GenerateTiles(tilesPerSide: number, seed: number)
    local tiles = {} :: {Tile}

    local rivers = {}
    for i = 1, RIVERS_COUNT do
        local random = Random.new(seed + i)
        local startX = random:NextNumber(-tilesPerSide/2, tilesPerSide/2)
        local startY = random:NextNumber(-tilesPerSide/2, tilesPerSide/2)
        
        rivers[i] = NoiseUtility.generatePerlinWorm(startX, startY, seed+i, tilesPerSide, 1, math.pi/8)
    end

    for x = 1, tilesPerSide do
        tiles[x] = {}
        for y = 1, tilesPerSide do
            local tile = {
                assetName = nil,
                noiseValue = nil
            } :: Tile

            local relaventX = x - tilesPerSide/2
            local relaventY = y - tilesPerSide/2
            
            -- Terrain
            local distanceFromCenter = math.sqrt(relaventX^2 + relaventY^2)
            local centerBias = calculateCenterBias(distanceFromCenter, tilesPerSide)

            local noiseValue = NoiseUtility.getNoiseValue(relaventX, relaventY, seed) + centerBias
            tile.noiseValue = noiseValue

            -- Rocks
            local rocksNoiseValue = NoiseUtility.getNoiseValue(relaventX, relaventY, seed+1, 5)

            local function getTile()
                -- Rivers
                for _, riverPoints in rivers do
                    local radius = noiseValue
                    local isRiver = isNearRiver(relaventX, relaventY, riverPoints, radius)

                    if isRiver then
                        return "Water"
                    end
                end

                -- Terrain
                for _, info in ipairs(NOISE_ASSET_RANGES) do
                    if rocksNoiseValue > 0.8 and noiseValue > 0.2 then
                        return "Rock"
                    end

                    if noiseValue > info.threshold then
                        return info.assetName
                    end
                end

                return "Rock"
            end

            tile.assetName = getTile()
            tiles[x][y] = tile
        end
    end
    return tiles
end

return TilingUtility