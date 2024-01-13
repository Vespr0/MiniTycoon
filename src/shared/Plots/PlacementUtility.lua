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
local DEFAULT_GRID_SIZE = 1
local OVERLAP_PARAMS = OverlapParams.new()
OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

local function snapCoordinate(alpha,gridSize)
    return math.floor(alpha / gridSize + 0.5) * gridSize
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
    for _,item in pairs(folder:GetChildren()) do
        local attribute = item:GetAttribute("LocalID")
        if attribute and attribute == localID then
            return item
        end
    end
    return false
end

function PlacementUtility.isPlacementValid(plot,model,overlapParams)
    local hitbox = model.Hitbox
    for _,part in pairs(hitbox:GetChildren()) do
        -- Add a bias, because touching counts even if they are not overllaping, witch makes placing droppers on the tiles impossible.
        local bias = Vector3.new(.1,.1,.1)
        local collidingParts = workspace:GetPartBoundsInBox(part.CFrame,part.Size-bias,overlapParams)
        for _,part in collidingParts do
            if part.Parent.Name == "Hitbox" then return false end
        end
    end
    return true;
end

return PlacementUtility