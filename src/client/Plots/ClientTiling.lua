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
local ReplicateBorder = Events.ReplicateBorder :: RemoteEvent

-- The plot border is a part with 4 Beams and 8 attachements, 2 attachments for each beam
-- Every beam name is ["Beam"..number] where number starts from 1 
-- Every attachment name is ["Attachment"..[T if it's the top or B if it's the bottom attachemtnt]..[number of the beam]]
-- So for example Attachment B3 and Attachment T3 are linked to Beam3

local PLOT_BORDER_HEIGHT = 2
local PLOT_BORDER_COLOR = Color3.fromRGB(175, 228, 241)

function ClientTiling.GenerateBorder(plot,root)
	local plotBorder = plot:FindFirstChild("PlotBorder")
	if not plotBorder then
		plotBorder = AssetsDealer.GetAssetFromName("Misc","PlotBorder",true);
		plotBorder.Parent = plot
		plotBorder.Name = "PlotBorder"	
	end

	plotBorder.CFrame = root.CFrame + Vector3.yAxis*(root.Size.Y/2 + PLOT_BORDER_HEIGHT/2)
	plotBorder.Size = Vector3.new(root.Size.X,PLOT_BORDER_HEIGHT,root.Size.X) -- Assuming a square plot

	local halfSide = plotBorder.Size.X / 2
	local halfHeight = plotBorder.Size.Y / 2

	local sideInfo = {
		{pos = Vector3.new(0, 0, -halfSide), rot = CFrame.Angles(0, 0, math.rad(90))},      -- Front
		{pos = Vector3.new(halfSide, 0, 0), rot = CFrame.Angles(0, math.rad(90), math.rad(90))},       -- Right
		{pos = Vector3.new(0, 0, halfSide), rot = CFrame.Angles(0, 0, math.rad(90))},       -- Back
		{pos = Vector3.new(-halfSide, 0, 0), rot = CFrame.Angles(0, math.rad(90), math.rad(90))}       -- Left
	}

	for i = 1, 4 do
		local topAttachment = plotBorder["AttachmentT"..i] :: Attachment
		local bottomAttachment = plotBorder["AttachmentB"..i] :: Attachment
		local beam = plotBorder["Beam"..i] :: Beam

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
	local origin = root.Position - Vector3.new( PlotUtility.MaxPlotWidth/2 + tileSize/2, 0,  PlotUtility.MaxPlotWidth/2 + tileSize/2)
	
	-- Generate tiles info
	local tilesPerSide = PlotUtility.MaxPlotWidth / tileSize
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
		ClientTiling.GenerateTiling(plot, plot.Root, seed)
	end)

	ReplicateBorder.OnClientEvent:Connect(function(root)
		if not root:IsA("BasePart") then
			error("Expected root to be a BasePart, got "..tostring(root))
		end

		ClientTiling.GenerateBorder(root.Parent, root)
	end)
end

return ClientTiling