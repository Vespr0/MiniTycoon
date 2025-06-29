local TiliingUtility = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NoiseUtility = require(ReplicatedStorage.Shared.Plots.NoiseUtility)

export type Tile = {
    assetName: string,
    noiseValue: number
}

local NOISE_ASSET_RANGES = {
    { threshold = 0.5, assetName = "Grass" },
    { threshold = 0.2, assetName = "Sand" },
    { threshold = -math.huge, assetName = "Water" }, -- fallback
}

function TiliingUtility.GetActualPlotWidth(plotLevel: number): number
    return plotLevel * 20 -- Assuming each plot level increases the width by 20 units
end

TiliingUtility.MaxPlotWidth = 100 -- Maximum plot width, can be adjusted as needed

function TiliingUtility.GenerateTiles(tilesPerSide: number, seed: number)
    local tiles = {} :: {Tile}
    for x = 1, tilesPerSide do
        tiles[x] = {}
        for y = 1, tilesPerSide do
            local tile = {
                assetName = nil,
                noiseValue = nil
            } :: Tile

            local relaventX = x - tilesPerSide/2
            local relaventY = y - tilesPerSide/2
            local noiseValue = NoiseUtility.getNoiseValue(relaventX, relaventY, seed)
            tile.noiseValue = noiseValue

            local rocksNoiseValue = NoiseUtility.getNoiseValue(relaventX, relaventY, seed+1, 5)

            for _, range in NOISE_ASSET_RANGES do
                if rocksNoiseValue > 0.8 and noiseValue > 0.2 then
                    tile.assetName = "Rock"
                    break
                end

                if noiseValue > range.threshold then
                    tile.assetName = range.assetName
                    break
                end
            end

            tiles[x][y] = tile
        end
    end
    return tiles
end

return TiliingUtility