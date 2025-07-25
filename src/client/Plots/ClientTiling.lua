local ClientTiling = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local AssetsDealer = require(ReplicatedStorage.Shared.AssetsDealer)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)
local TilingUtility = require(ReplicatedStorage.Shared.Plots.TilingUtility)

local Events = ReplicatedStorage.Events
local ReplicateTiling = Events.ReplicateTiling :: RemoteEvent
local ReplicateBorder = Events.ReplicateBorder :: RemoteEvent

-- The plot border is a part with 4 Beams and 8 attachements, 2 attachments for each beam
-- Every beam name is ["Beam"..number] where number starts from 1
-- Every attachment name is ["Attachment"..[T if it's the top or B if it's the bottom attachemtnt]..[number of the beam]]
-- So for example Attachment B3 and Attachment T3 are linked to Beam3

local PLOT_BORDER_HEIGHT = 2
local PLOT_BORDER_COLOR = Color3.fromRGB(175, 228, 241)
local WATER_BASE_HEIGHT = 0.4 -- Height of the water base part
local WATER_BASE_OFFSET = 0 -- How much lower the water sits compared to tiles
local WATER_BOTTOM_HEIGHT = 1.0 -- Height of the water bottom part
local WATER_BOTTOM_OFFSET = -1 -- How much lower the water bottom sits

function ClientTiling.GenerateBorder(plot, root)
	local plotBorder = plot:FindFirstChild("PlotBorder")
	if not plotBorder then
		plotBorder = AssetsDealer.GetAssetFromName("Misc", "PlotBorder", true)
		plotBorder.Parent = plot
		plotBorder.Name = "PlotBorder"
	end

	-- Since the root is invisible it feels intuitive for it to be cancollide false
	root.CanCollide = false

	plotBorder.CFrame = root.CFrame + Vector3.yAxis * (root.Size.Y / 2 + PLOT_BORDER_HEIGHT / 2)
	plotBorder.Size = Vector3.new(root.Size.X, PLOT_BORDER_HEIGHT, root.Size.X) -- Assuming a square plot

	local halfSide = plotBorder.Size.X / 2
	local halfHeight = plotBorder.Size.Y / 2

	local sideInfo = {
		{ pos = Vector3.new(0, 0, -halfSide), rot = CFrame.Angles(0, 0, math.rad(90)) }, -- Front
		{ pos = Vector3.new(halfSide, 0, 0), rot = CFrame.Angles(0, math.rad(90), math.rad(90)) }, -- Right
		{ pos = Vector3.new(0, 0, halfSide), rot = CFrame.Angles(0, 0, math.rad(90)) }, -- Back
		{ pos = Vector3.new(-halfSide, 0, 0), rot = CFrame.Angles(0, math.rad(90), math.rad(90)) }, -- Left
	}

	for i = 1, 4 do
		local topAttachment = plotBorder["AttachmentT" .. i] :: Attachment
		local bottomAttachment = plotBorder["AttachmentB" .. i] :: Attachment
		local beam = plotBorder["Beam" .. i] :: Beam

		local info = sideInfo[i]
		local centerPos = info.pos
		local rotation = info.rot

		local topPos = Vector3.new(centerPos.X, halfHeight, centerPos.Z)
		local bottomPos = Vector3.new(centerPos.X, -halfHeight, centerPos.Z)

		topAttachment.CFrame = CFrame.new(topPos) * rotation
		bottomAttachment.CFrame = CFrame.new(bottomPos) * rotation

		beam.Width0 = plotBorder.Size.X
		beam.Width1 = plotBorder.Size.X
		beam.Color = ColorSequence.new(PLOT_BORDER_COLOR)
	end
end

function ClientTiling.GenerateTiling(plot, root, seed)
	-- Make root invisible
	root.Transparency = 1

	local tileSize = GameConfig.TileSize

	--local actualPlotWidth = TilingUtility.GetActualPlotWidth(plotLevel)
	local origin = root.Position
		- Vector3.new(PlotUtility.MaxPlotWidth / 2 + tileSize / 2, 0, PlotUtility.MaxPlotWidth / 2 + tileSize / 2)

	-- Generate tiles info
	local tilesPerSide = PlotUtility.MaxPlotWidth / tileSize
	local tiles = TilingUtility.GenerateTiles(tilesPerSide, seed)

	-- Clear existing tiles
	plot.Tiles:ClearAllChildren()

	-- Create the large water part that covers the entire plot
	ClientTiling.CreateWaterBase(plot, root)

	for x = 1, tilesPerSide do
		RunService.RenderStepped:Wait() -- Yield to avoid freezing the client
		for y = 1, tilesPerSide do
			local tile = tiles[x][y]

			-- Skip placing tiles where water should be - let the water base show through
			if tile.assetName == "Water" then
				continue
			end

			local asset = AssetsDealer.GetTile(tile.assetName)
			local tileModel = asset.Model :: Model
			tileModel.Parent = plot.Tiles
			tileModel:PivotTo(CFrame.new(origin + Vector3.new(x * tileSize, 0, y * tileSize)))

			asset:Destroy()
		end
	end
end

function ClientTiling.CreateWaterBase(plot, root)
	-- Remove existing water parts if they exist
	-- local existingWater = plot:FindFirstChild("WaterBase")
	-- if existingWater then
	-- 	existingWater:Destroy()
	-- end
	-- local existingWaterBottom = plot:FindFirstChild("WaterBottom")
	-- if existingWaterBottom then
	-- 	existingWaterBottom:Destroy()
	-- end

	local plotSize = PlotUtility.MaxPlotWidth

	-- Create the water bottom part (seafloor/lakebed)
	local waterBottom = Instance.new("Part")
	waterBottom.Name = "WaterBottom"
	waterBottom.Material = Enum.Material.Sand
	waterBottom.TopSurface = Enum.SurfaceType.Smooth
	waterBottom.BottomSurface = Enum.SurfaceType.Smooth
	waterBottom.Anchored = true
	waterBottom.CanCollide = false
	waterBottom.Size = Vector3.new(plotSize, WATER_BOTTOM_HEIGHT, plotSize)
	waterBottom.CFrame = root.CFrame + Vector3.new(0, WATER_BOTTOM_OFFSET, 0)
	-- TODO: Maybe get the color from the Sand tyle? (AssetsDealer)
	waterBottom.Color = Color3.fromRGB(167, 151, 86) -- Sandy brown color
	waterBottom.Parent = plot

	-- Create the water base part
	local waterBase = Instance.new("Part")
	waterBase.Name = "WaterBase"
	waterBase.Material = Enum.Material.SmoothPlastic
	waterBase.TopSurface = Enum.SurfaceType.Smooth
	waterBase.BottomSurface = Enum.SurfaceType.Smooth
	waterBase.Anchored = true
	waterBase.CanCollide = false
	waterBase.Transparency = 0.3
	waterBase.Size = Vector3.new(plotSize, WATER_BASE_HEIGHT, plotSize)
	waterBase.CFrame = root.CFrame + Vector3.new(0, WATER_BASE_OFFSET, 0)
	waterBase.Color = Color3.fromRGB(67, 178, 229)
	waterBase.Parent = plot
end

function ClientTiling.Setup()
	ReplicateTiling.OnClientEvent:Connect(function(plotName, seed)
		local plot = workspace.Plots:FindFirstChild(plotName)
		if not plot then
			error("Plot with name " .. plotName .. " not found.")
		end

		-- Call LoadRootAndTiles
		ClientTiling.GenerateTiling(plot, plot.Root, seed)
	end)

	ReplicateBorder.OnClientEvent:Connect(function(root)
		if not root:IsA("BasePart") then
			error("Expected root to be a BasePart, got " .. tostring(root))
		end

		ClientTiling.GenerateBorder(root.Parent, root)
	end)
end

return ClientTiling
