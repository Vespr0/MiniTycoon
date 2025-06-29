local ClientTiling = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local AssetsDealer = require(ReplicatedStorage.Shared.AssetsDealer)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)
local TilingUtility = require(ReplicatedStorage.Shared.Plots.TilingUtility)
local ColorsUtility = require(ReplicatedStorage.Shared.Utility.ColorUtility)

local Events = ReplicatedStorage.Events
local ReplicateTiling = Events.ReplicateTiling :: RemoteEvent

function ClientTiling.GenerateTiling(plot, root, seed)
	-- Make root invisible
	root.Transparency = .5 -- 1

	local tileSize = GameConfig.TileSize
	
	--local actualPlotWidth = TilingUtility.GetActualPlotWidth(plotLevel)
	local origin = root.Position - Vector3.new( TilingUtility.MaxPlotWidth/2 + tileSize/2, 0,  TilingUtility.MaxPlotWidth/2 + tileSize/2)
	
	-- Generate tiles info
	local tilesPerSide = TilingUtility.MaxPlotWidth / tileSize
	local tiles = TilingUtility.GenerateTiles(tilesPerSide, seed)
	
	-- Clear existing tiles
	plot.Tiles:ClearAllChildren()
	
	for x = 1, tilesPerSide do
		RunService.RenderStepped:Wait() -- Yield to avoid freezing the client
		for y = 1, tilesPerSide do
			local tile = tiles[x][y]
			local asset = AssetsDealer.GetTile(tile.assetName)

			local tileModel = asset.Model :: Model
			tileModel.Parent = plot.Tiles
			tileModel:PivotTo(CFrame.new(origin + Vector3.new(x * tileSize, 0, y * tileSize)))

			if(tile.assetName == "Water") then
				tileModel:SetAttribute("IsWater", true)

				tileModel.Water.Color = ColorsUtility.Darken(tileModel.Water.Color, tile.noiseValue*2)
			end

			asset:Destroy()
		end
	end
end

function ClientTiling.Setup()
	ReplicateTiling.OnClientEvent:Connect(function(plotName,seed)
		local plot = workspace.Plots:FindFirstChild(plotName)
		if not plot then
			error("Plot with name "..plotName.." not found.")
		end

		-- Call LoadRootAndTiles
		warn(seed)
		ClientTiling.GenerateTiling(plot, plot.Root, seed)
	end)
end

return ClientTiling