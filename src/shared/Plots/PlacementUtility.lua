local PlacementUtility = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
    for _,item in folder:GetChildren() do
        local attribute = item:GetAttribute("LocalID")
        if attribute and attribute == localID then
            return item
        end
	end
	warn(`Couldn't find item with localID "{localID}" in folder "{folder.Name}".`)
    return false
end

function PlacementUtility.WaitForItemFromLocalID(folder,localID,waitTime)
	local model, timeout
	local start = os.clock()
	repeat
		timeout = (os.clock()-start) > (waitTime or 1)
		model = PlacementUtility.GetItemFromLocalID(folder,localID)
		RunService.RenderStepped:Wait()	
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
    return true
end

return PlacementUtility