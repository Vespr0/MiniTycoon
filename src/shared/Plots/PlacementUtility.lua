local PlacementUtility = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TilingUtility = require(ReplicatedStorage.Shared.Plots.TilingUtility)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)

local Player
if RunService:IsClient() then
	Player = Players.LocalPlayer
end

-- Folders --
local Plots = workspace:WaitForChild("Plots")

-- Constants --
local DEFAULT_GRID_SIZE = 1 --/ 2
local OVERLAP_PARAMS = OverlapParams.new()
OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Include
OVERLAP_PARAMS.FilterDescendantsInstances = { workspace.Plots }

local function snapCoordinate(alpha, gridSize)
	return math.round(alpha / gridSize) * gridSize
end

function PlacementUtility.GetClientPlot()
	return Plots:WaitForChild(Player:GetAttribute("Plot"))
end

function PlacementUtility.GhostModel(model)
	for _, desc in pairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			if desc.Transparency < 1 then
				desc.Transparency = 0
			end
			desc.CanCollide = false
			desc.CastShadow = false
			desc.Anchored = true
		end
	end
end

function PlacementUtility.SnapPositionToGrid(position, gridSize, ignoreY)
	gridSize = gridSize or DEFAULT_GRID_SIZE
	local posX = snapCoordinate(position.X, gridSize)
	local posY = not ignoreY and snapCoordinate(position.Y, gridSize) or position.Y
	local posZ = snapCoordinate(position.Z, gridSize)
	return Vector3.new(posX, posY, posZ)
end

function PlacementUtility.GetItemFromLocalID(folder, localID)
	for _, item in folder:GetChildren() do
		local attribute = item:GetAttribute("LocalID")
		if attribute and attribute == localID then
			return item
		end
	end
	-- warn(`Couldn't find item with localID "{localID}" in folder "{folder.Name}".`)
	return false
end

function PlacementUtility.WaitForItemFromLocalID(folder: Folder, localID: number, waitTime: number?)
	local model, timeout
	local start = os.clock()
	repeat
		timeout = (os.clock() - start) > (waitTime or 1)
		model = PlacementUtility.GetItemFromLocalID(folder, localID)
		RunService.RenderStepped:Wait()
	until model or timeout

	if timeout and not model  then
		error(`Couldn't find item with localID "{localID}" in folder "{folder:GetFullName()}".`)
	end

	return model
end

local function checkHitboxCollisions(model, overlapParams): boolean
	local hitbox = model.Hitbox
	for _, hitPart in hitbox:GetChildren() do
		-- Add a bias, because touching counts even if they are not overlapping, which makes placing droppers on the tiles impossible.
		local bias = Vector3.new(0.2, 0.2, 0.2)
		local collidingParts = workspace:GetPartBoundsInBox(hitPart.CFrame, hitPart.Size - bias, overlapParams)
		for _, part in collidingParts do
			if part.Parent.Name == "Hitbox" then
				return false
			end
		end
	end
	return true
end

local function checkPlotBounds(model, plot): boolean
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { plot.Root }

	for _, edge in model.PrimaryPart:GetChildren() do
		if edge.Name == "Edge" then
			local raycast = workspace:Raycast(edge.WorldPosition, -Vector3.yAxis * 1000, raycastParams)
			local isEdgeOnPlot = raycast and raycast.Instance
			if not isEdgeOnPlot then
				return false
			end
		end
	end
	return true
end

function PlacementUtility.GetTileUnderModel(plot, model): TilingUtility.Tile?
	if not model.PrimaryPart then
		warn("Model has no PrimaryPart")
		return nil
	end

	-- Get plot attributes for tile generation
	-- The owner user id is the tiling seed
	local plotSeed = plot:GetAttribute("OwnerID")
	local _plotLevel = plot:GetAttribute("Level") or 1

	if not plotSeed then
		warn("Plot has no OwnerID attribute which is needed as the tiling seed")
		return nil
	end

	-- Use the model's primary part position
	local modelPosition = model.PrimaryPart.Position
	local plotRootPosition = plot.Root.Position

	-- Generate the tile at this position
	local tile = TilingUtility.GenerateSingleTileAtAbsolute(modelPosition, plotRootPosition, plotSeed)

	return tile
end

function PlacementUtility.GetTilesAtEdges(plot, model): { [string]: TilingUtility.Tile? }
	if not model.PrimaryPart then
		warn("Model has no PrimaryPart")
		return {}
	end

	-- Get plot attributes for tile generation
	local plotSeed = plot:GetAttribute("OwnerID")

	if not plotSeed then
		warn("Plot has no OwnerID attribute")
		return {}
	end

	local plotRootPosition = plot.Root.Position
	local edgeTiles = {}

	-- Get tiles at each Edge attachment position
	for i, edge in model.PrimaryPart:GetChildren() do
		if edge:IsA("Attachment") and edge.Name == "Edge" then
			local edgeWorldPosition = edge.WorldPosition
			local tile = TilingUtility.GenerateSingleTileAtAbsolute(
				edgeWorldPosition,
				plotRootPosition,
				plotSeed
			)
			edgeTiles[i] = tile.assetName
		end
	end

	return edgeTiles
end

function PlacementUtility.isPlacementValid(plot, model, overlapParams, itemConfig): boolean
	-- Get the tile under the model for debugging
	-- local tile = PlacementUtility.GetTileUnderModel(plot, model)
	-- if tile then
	-- 	print(`tile: {tile.assetName}`)
	-- else
	-- 	print("Model center is not on any tile or outside plot bounds")
	-- end

	-- Get tiles at each edge for debugging
	-- TODO: default values for these two flags should be centralized
	local CanPlaceOnGround = itemConfig.CanPlaceOnGround or true
	local CanPlaceOnWater = itemConfig.CanPlaceOnWater or false

	local edgeTiles = PlacementUtility.GetTilesAtEdges(plot, model)
	-- print(table.unpack(edgeTiles))
	for edgeIndex, edgeTile in edgeTiles do
		if edgeTile then
			if edgeTile == "Water" then
				if not CanPlaceOnWater then
					return false
				end
			else
				if not CanPlaceOnGround then
					return false
				end
			end
		end
	end

	return checkHitboxCollisions(model, overlapParams) and checkPlotBounds(model, plot)
end

return PlacementUtility
