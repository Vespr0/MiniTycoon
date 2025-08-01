local TilingUtility = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NoiseUtility = require(ReplicatedStorage.Shared.Plots.NoiseUtility)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)

export type Tile = {
	assetName: string,
	noiseValue: number,
}

export type TilePosition = {
	x: number,
	y: number,
}

export type TerrainConfig = {
	noiseAssetRanges: { { threshold: number, assetName: string } },
	riversCount: number,
	rockThreshold: number,
	rockNoiseThreshold: number,
	grassFieldRadius: number,
}

local DEFAULT_TERRAIN_CONFIG: TerrainConfig = {
	noiseAssetRanges = {
		{ threshold = 0.7, assetName = "Grass" },
		{ threshold = 0.5, assetName = "Sand" },
		{ threshold = -math.huge, assetName = "Water" }, -- fallback
	},
	riversCount = 3,
	rockThreshold = 0.8,
	rockNoiseThreshold = 0.2,
	grassFieldRadius = 4, -- Radius from center where rivers are not allowed
}

TilingUtility.TILES_PER_SIDE = PlotUtility.MaxPlotWidth / GameConfig.TileSize

-- Position conversion utilities
function TilingUtility.AbsoluteToTilePosition(absolutePosition: Vector3, plotRootPosition: Vector3): TilePosition
	local tileSize = GameConfig.TileSize

	-- Convert world position to the noise coordinate system used in GenerateTiles
	-- Client places tiles starting from index 1, at positions: origin + Vector3.new(x * tileSize, 0, y * tileSize)
	-- where origin = plotRootPosition - Vector3.new(MaxPlotWidth/2 + tileSize/2, 0, MaxPlotWidth/2 + tileSize/2)
	--
	-- To reverse this:
	-- 1. Calculate what the client's origin would be
	local maxPlotWidth = PlotUtility.MaxPlotWidth
	local clientOrigin = plotRootPosition
		- Vector3.new(maxPlotWidth / 2 + tileSize / 2, 0, maxPlotWidth / 2 + tileSize / 2)

	-- 2. Find the array indices this position would correspond to
	local offsetFromOrigin = absolutePosition - clientOrigin
	local arrayX = offsetFromOrigin.X / tileSize -- This gives us the x index (can be fractional)
	local arrayY = offsetFromOrigin.Z / tileSize -- This gives us the y index (can be fractional)

	-- 3. Round to nearest integer to get the actual tile indices (since tiles are discrete)
	local roundedArrayX = math.round(arrayX)
	local roundedArrayY = math.round(arrayY)

	-- 4. Convert array indices to noise coordinates (same as GenerateTiles does)
	local tileX = roundedArrayX - TilingUtility.TILES_PER_SIDE / 2
	local tileY = roundedArrayY - TilingUtility.TILES_PER_SIDE / 2

	return {
		x = tileX,
		y = tileY,
	}
end

-- Terrain generation utilities
local function calculateCenterBias(relativeX: number, relativeY: number): number
	local maxDistance = TilingUtility.TILES_PER_SIDE / 2 -- Distance from center to edge

	-- Use Chebyshev distance (max of x,y) for square island shape
	local squareDistance = math.max(math.abs(relativeX), math.abs(relativeY))
	local normalizedDistance = math.min(squareDistance / maxDistance, 1) -- Clamp to [0, 1]

	-- More aggressive square island generation - positive bias at center, negative at edges
	-- This forces water at borders and guarantees land in the center
	local bias = math.cos(normalizedDistance * math.pi / 2) ^ 2 * 1.2 - normalizedDistance * 0.4

	return bias
end

local function isNearRiver(x: number, y: number, riverPoints: any, radius: number): boolean
	for _, point in riverPoints do
		local dx = x - point.x
		local dy = y - point.y
		if (dx * dx + dy * dy) <= radius * radius then
			return true
		end
	end
	return false
end

local function isInGrassField(x: number, y: number, grassFieldRadius: number): boolean
	local distanceFromCenter = math.sqrt(x * x + y * y)
	return distanceFromCenter <= grassFieldRadius
end

local function generateRivers(seed: number, riversCount: number): { any }
	local rivers = {}
	for i = 1, riversCount do
		local random = Random.new(seed + i)
		local startX = random:NextNumber(-TilingUtility.TILES_PER_SIDE / 2, TilingUtility.TILES_PER_SIDE / 2)
		local startY = random:NextNumber(-TilingUtility.TILES_PER_SIDE / 2, TilingUtility.TILES_PER_SIDE / 2)

		rivers[i] =
			NoiseUtility.generatePerlinWorm(startX, startY, seed + i, TilingUtility.TILES_PER_SIDE * 2, 1, math.pi / 8)
	end
	return rivers
end

local function determineTileType(
	relativeX: number,
	relativeY: number,
	noiseValue: number,
	rocksNoiseValue: number,
	rivers: { any },
	config: TerrainConfig
): string
	-- Check if we're in the grass field radius (center area where rivers are not allowed)
	local inGrassField = isInGrassField(relativeX, relativeY, config.grassFieldRadius)

	-- Rivers (only if not in grass field)
	if not inGrassField then
		for _, riverPoints in rivers do
			local radius = noiseValue
			local isRiver = isNearRiver(relativeX, relativeY, riverPoints, radius)
			if isRiver then
				return "Water"
			end
		end
	end

	-- Rocks
	if rocksNoiseValue > config.rockThreshold and noiseValue > config.rockNoiseThreshold then
		return "Rock"
	end

	-- Terrain based on noise ranges
	for _, info in ipairs(config.noiseAssetRanges) do
		if noiseValue > info.threshold then
			return info.assetName
		end
	end

	return "Rock" -- fallback
end

local function generateSingleTileData(
	relativeX: number,
	relativeY: number,
	seed: number,
	rivers: { any },
	config: TerrainConfig
): Tile
	-- Calculate terrain noise with center bias
	local centerBias = calculateCenterBias(relativeX, relativeY)
	local noiseValue = NoiseUtility.getNoiseValue(relativeX, relativeY, seed) + centerBias

	-- Calculate rocks noise
	local rocksNoiseValue = NoiseUtility.getNoiseValue(relativeX, relativeY, seed + 1, 5)

	-- Create tile
	local tile: Tile = {
		assetName = determineTileType(relativeX, relativeY, noiseValue, rocksNoiseValue, rivers, config),
		noiseValue = noiseValue,
	}

	return tile
end

function TilingUtility.GetActualPlotWidth(plotLevel: number): number
	return plotLevel * 10 + 10 -- Assuming each plot level increases the width by 10 units
end

function TilingUtility.GenerateSingleTile(tilePosition: TilePosition, seed: number, config: TerrainConfig?): Tile
	local terrainConfig = config or DEFAULT_TERRAIN_CONFIG
	local rivers = generateRivers(seed, terrainConfig.riversCount)

	-- Use the continuous tile coordinates directly for noise generation
	return generateSingleTileData(tilePosition.x, tilePosition.y, seed, rivers, terrainConfig)
end

function TilingUtility.GenerateTiles(seed: number, config: TerrainConfig?): { { Tile } }
	local terrainConfig = config or DEFAULT_TERRAIN_CONFIG
	local tiles = {} :: { { Tile } }

	local rivers = generateRivers(seed, terrainConfig.riversCount)

	for x = 1, TilingUtility.TILES_PER_SIDE do
		tiles[x] = {}
		for y = 1, TilingUtility.TILES_PER_SIDE do
			local relativeX = x - TilingUtility.TILES_PER_SIDE / 2
			local relativeY = y - TilingUtility.TILES_PER_SIDE / 2

			tiles[x][y] = generateSingleTileData(relativeX, relativeY, seed, rivers, terrainConfig)
		end
	end
	return tiles
end

function TilingUtility.GenerateSingleTileAtAbsolute(
	absolutePosition: Vector3,
	plotRootPosition: Vector3,
	seed: number,
	config: TerrainConfig?
): Tile
	local tilePosition = TilingUtility.AbsoluteToTilePosition(absolutePosition, plotRootPosition)
	-- print(`({tilePosition.x}, {tilePosition.y}) for {absolutePosition}`)
	return TilingUtility.GenerateSingleTile(tilePosition, seed, config)
end

return TilingUtility
