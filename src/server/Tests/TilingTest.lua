local TilingTest = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Terrain = workspace.Terrain

-- Modules
local TilingUtility = require(Shared.Plots.TilingUtility)
local PlotUtility = require(Shared.Plots.PlotUtility)
local GameConfig = require(Shared.GameConfig)

TilingTest.Enabled = true

-- Store placed tile data for testing
local placedTiles = {}
local terrainBlocks = {}

function TilingTest.Run()
	-- Clear any existing test data
	TilingTest.Cleanup()
	placedTiles = {}
	terrainBlocks = {}

	local plotRoot = workspace.Plots.Plot7.Root

	print("=== GENERATING TERRAIN TILES ===")
	print(`Plot root at: {plotRoot.Position}`)

	-- Generate tiles using a fixed seed
	local seed = 1075120350
	local tiles = TilingUtility.GenerateTiles(seed)

	-- Calculate origin exactly like the client does
	local tileSize = GameConfig.TileSize
	local maxPlotWidth = PlotUtility.MaxPlotWidth
	local origin = plotRoot.Position - Vector3.new(maxPlotWidth / 2 + tileSize / 2, 0, maxPlotWidth / 2 + tileSize / 2)

	print(`Client origin: {origin}`)
	print(`Generating {TilingUtility.TILES_PER_SIDE}x{TilingUtility.TILES_PER_SIDE} terrain tiles...`)

	-- Place terrain tiles exactly like the client does
	for x = 1, TilingUtility.TILES_PER_SIDE do
		if x % 10 == 0 then
			task.wait() -- Yield occasionally to avoid freezing
		end

		for y = 1, TilingUtility.TILES_PER_SIDE do
			local tile = tiles[x][y]

			-- Position it exactly like the client would
			local worldPosition = origin + Vector3.new(x * tileSize, 0, y * tileSize)

			-- Choose material and fill based on tile type
			local material = Enum.Material.Grass

			if tile.assetName == "Grass" then
				material = Enum.Material.Grass
			elseif tile.assetName == "Sand" then
				material = Enum.Material.Sand
			elseif tile.assetName == "Water" then
				material = Enum.Material.Water
			elseif tile.assetName == "Rock" then
				material = Enum.Material.Rock
			else
				error("Unknown tile asset name: " .. tile.assetName)
			end

			-- Create CFrame and size for FillBlock
			local blockCFrame = CFrame.new(worldPosition + Vector3.new(0, 0, 0))
			local blockSize = Vector3.new(tileSize, 5, tileSize)

			-- Fill the terrain
			if not (tile.assetName == "Water") then
				Terrain:FillBlock(blockCFrame, blockSize, material)
			end

			-- Store block info for cleanup
			table.insert(terrainBlocks, {
				cframe = blockCFrame,
				size = blockSize,
			})

			-- Store tile info for testing
			table.insert(placedTiles, {
				originalTile = tile,
				arrayX = x,
				arrayY = y,
				worldPosition = worldPosition,
				blockCFrame = blockCFrame,
				blockSize = blockSize,
				material = material,
			})
		end
	end

	print(`Generated {#placedTiles} terrain tiles`)
	print("=== TESTING COORDINATE CONVERSION ===")

	-- Test conversion on random tiles
	local testCount = 10
	local successCount = 0

	for i = 1, testCount do
		-- Pick a random tile
		local randomIndex = math.random(1, #placedTiles)
		local testTile = placedTiles[randomIndex]

		local randomHeight = math.random(-100, 100)

		-- Spread that still keeps the position inside the tile
		local randomSpreadX = math.random(-tileSize * 4, tileSize * 4) / 10
		local randomSpreadZ = math.random(-tileSize * 4, tileSize * 4) / 10

		local worldPosition = testTile.worldPosition
			+ (Vector3.yAxis * randomHeight)
			+ Vector3.new(randomSpreadX, 0, randomSpreadZ)

		-- Apply grid snapping like the real game does
		-- local PlacementUtility = require(game.ReplicatedStorage.Shared.Plots.PlacementUtility)
		-- local snappedPosition = PlacementUtility.SnapPositionToGrid(worldPosition, nil, true)

		-- Use our conversion function to get the tile type at the SNAPPED position
		local convertedTile = TilingUtility.GenerateSingleTileAtAbsolute(worldPosition, plotRoot.Position, seed)

		-- Check if they match
		local matches = testTile.originalTile.assetName == convertedTile.assetName
		if matches then
			successCount = successCount + 1
			-- Mark successful tiles with a green marker
			local marker = Instance.new("Part")
			marker.Name = "SuccessMarker"
			marker.Size = Vector3.new(0.5, 6, 0.5)
			marker.Position = Vector3.new(worldPosition.X, plotRoot.Position.Y + 5, worldPosition.Z)
			marker.Color = Color3.fromRGB(0, 255, 0)
			marker.Material = Enum.Material.Neon
			marker.Anchored = true
			marker.Parent = workspace
		else
			-- Mark failed tiles with a red marker
			local marker = Instance.new("Part")
			marker.Name = "FailMarker"
			marker.Size = Vector3.new(0.5, 6, 0.5)
			marker.Position = Vector3.new(worldPosition.X, plotRoot.Position.Y + 5, worldPosition.Z)
			marker.Color = Color3.fromRGB(255, 0, 0)
			marker.Material = Enum.Material.Neon
			marker.Anchored = true
			marker.Parent = workspace
		end

		print(`Test {i}: Tile [{testTile.arrayX},{testTile.arrayY}]`)
		print(`  Original position: {worldPosition}`)
		-- print(`  Snapped position: {snappedPosition}`)
		print(`  Original: {testTile.originalTile.assetName} (noise: {testTile.originalTile.noiseValue})`)
		print(`  Converted: {convertedTile.assetName} (noise: {convertedTile.noiseValue})`)
		print(`  Match: {matches}`)
		print("")
	end

	print(`=== RESULTS: {successCount}/{testCount} conversions successful ===`)

	if successCount == testCount then
		print("All coordinate conversions are working correctly!")
	else
		error("❌ Some coordinate conversions failed. Check red markers in workspace.")
	end

	print("Green markers = successful conversions")
	print("Red markers = failed conversions")
	print("Call TilingTest.Cleanup() to remove all test terrain and markers")
end

-- Clean up function to remove all test terrain and markers
function TilingTest.Cleanup()
	local terrain = workspace.Terrain

	-- Remove all terrain blocks we created
	for _, block in ipairs(terrainBlocks) do
		terrain:FillBlock(block.cframe, block.size, Enum.Material.Air)
	end

	-- Remove all marker parts
	for _, child in workspace:GetChildren() do
		if
			child.Name:match("^Tile_")
			or child.Name == "SuccessMarker"
			or child.Name == "FailMarker"
			or child.Name:match("^TestMarker_")
		then
			child:Destroy()
		end
	end

	placedTiles = {}
	terrainBlocks = {}
	print("Test cleanup completed - terrain cleared and markers removed.")
end

return TilingTest
