local PlacementUtility = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TilingUtility = require(ReplicatedStorage.Shared.Plots.TilingUtility)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local AssetsDealer = require(ReplicatedStorage.Shared.AssetsDealer)

local Player
if RunService:IsClient() then
    Player = Players.LocalPlayer
end

-- Folders --
local Plots = workspace:WaitForChild("Plots")

-- Constants --
local DEFAULT_GRID_SIZE = 1/2
local OVERLAP_PARAMS = OverlapParams.new()
OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Include
OVERLAP_PARAMS.FilterDescendantsInstances = {workspace.Plots}

local function snapCoordinate(alpha,gridSize)
    return math.round(alpha / gridSize) * gridSize
end

function PlacementUtility.GetClientPlot()
    return Plots:WaitForChild(Player:GetAttribute("Plot"))
end

function PlacementUtility.GhostModel(model)
    for _,desc in pairs(model:GetDescendants()) do
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

function PlacementUtility.SnapPositionToGrid(position,gridSize,ignoreY)
    gridSize = gridSize or DEFAULT_GRID_SIZE
    local posX = snapCoordinate(position.X,gridSize)
	local posY = not ignoreY and snapCoordinate(position.Y,gridSize) or position.Y
    local posZ = snapCoordinate(position.Z,gridSize)
    return Vector3.new(posX,posY,posZ)
end

function PlacementUtility.GetItemFromLocalID(folder,localID)
    print(folder.Name,folder.Parent.Name,#folder:GetChildren())
    for _,model in folder:GetChildren() do
        local attribute = model:GetAttribute("LocalID")
        if attribute and attribute == localID then
            return model
        end
	end
	warn(`Couldn't find item with localID "{localID}" in folder "{folder.Name}".`)
    return false
end

function PlacementUtility.WaitForItemFromLocalID(folder,localID,waitTime)
	local model, timeout
	local start = os.clock()
	repeat
		timeout = (os.clock()-start) > (waitTime or 5)
		model = PlacementUtility.GetItemFromLocalID(folder,localID)
		task.wait(.1)
	until model or timeout
	return model
end

function PlacementUtility.isPlacementValid(plot,model,overlapParams)
    local hitbox = model.Hitbox
    local root = model.PrimaryPart
    for _,hitPart in hitbox:GetChildren() do
        -- Add a bias, because touching counts even if they are not overllaping, witch makes placing droppers on the tiles impossible.
        local bias = Vector3.new(.2,.2,.2)
        local collidingParts = workspace:GetPartBoundsInBox(hitPart.CFrame,hitPart.Size-bias,overlapParams)
        for _,part in collidingParts do
            if part.Parent.Name == "Hitbox" then return false end
        end
    end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = {plot.Root}
    for _,edge in model.PrimaryPart:GetChildren() do
        if edge.Name == "Edge" then
            local raycast = workspace:Raycast(edge.WorldPosition,-Vector3.yAxis*1000,raycastParams)
            local isEdgeOnPlot = raycast and raycast.Instance
            if not isEdgeOnPlot then
                return false
            end
        end
    end
    
    -- Check water placement rules
    local itemName = model:GetAttribute("ItemName")
    if itemName then
        local isOnWater = PlacementUtility.IsPositionOnWater(plot, model.PrimaryPart.Position)
        local itemConfig = PlacementUtility.GetItemConfig(itemName)
        
        if itemConfig then
            local canPlaceOnWater = itemConfig.CanPlaceOnWater or false
            local canPlaceOnGround = itemConfig.CanPlaceOnGround ~= false -- Default to true
            
            if isOnWater and not canPlaceOnWater then
                return false
            elseif not isOnWater and not canPlaceOnGround then
                return false
            end
        end
    end
    
    return true
end

function PlacementUtility.IsPositionOnWater(plot, position)
    -- Get the plot's seed from the player who owns it
    local plotName = plot.Name
    local userId = tonumber(plotName:match("Plot_(%d+)"))
    if not userId then
        return false
    end
    
    local seed = userId
    local tileSize = GameConfig.TileSize
    local plotRoot = plot.Root
    
    -- Convert world position to tile coordinates
    local origin = plotRoot.Position - Vector3.new(PlotUtility.MaxPlotWidth/2 + tileSize/2, 0, PlotUtility.MaxPlotWidth/2 + tileSize/2)
    local relativePos = position - origin
    local tileX = math.floor(relativePos.X / tileSize) + 1
    local tileY = math.floor(relativePos.Z / tileSize) + 1
    
    local tilesPerSide = PlotUtility.MaxPlotWidth / tileSize
    
    -- Check if position is within plot bounds
    if tileX < 1 or tileX > tilesPerSide or tileY < 1 or tileY > tilesPerSide then
        return false
    end
    
    -- Generate the tile info for this specific position
    local tiles = TilingUtility.GenerateTiles(tilesPerSide, seed)
    local tile = tiles[tileX] and tiles[tileX][tileY]
    
    return tile and tile.assetName == "Water"
end

function PlacementUtility.GetItemConfig(itemName)
    local item = AssetsDealer.GetItem(itemName)
    if item and item:FindFirstChild("config") then
        return require(item.config)
    end
    return nil
end

return PlacementUtility