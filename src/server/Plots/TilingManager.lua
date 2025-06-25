local TilingManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local AssetsDealer = require(ReplicatedStorage.Shared.AssetsDealer)

--- Loads and tiles the plot root with tiles.
function TilingManager.LoadRootAndTiles(plot, root, plotLevel)
	local tileSize = GameConfig.TileSize
	local actualPlotWidth = plotLevel*10
	root.Transparency = 1
	root.Size = Vector3.new(actualPlotWidth, 1, actualPlotWidth)
	local origin = root.Position - Vector3.new(actualPlotWidth/2 + tileSize/2, 0, actualPlotWidth/2 + tileSize/2)

	for x = 1, actualPlotWidth / tileSize do
		for y = 1, actualPlotWidth / tileSize do
			local asset = AssetsDealer.GetTile("Grass")
			local tile = asset.Model :: Model
			tile.Parent = plot.Tiles
            print(tileSize)
			tile:PivotTo(CFrame.new(origin + Vector3.new(x * tileSize, 0, y * tileSize)))
			asset:Destroy()
		end
	end
end

return TilingManager
