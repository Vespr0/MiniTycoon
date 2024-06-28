local PlotLoader = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")
-- Modules --
local PlotUtility = require(Shared.Plots.PlotUtility)
local AssetsDealer = require(ReplicatedStorage.Shared.AssetsDealer)
local ItemsAccess = require(Server.Data.DataAccessModules.ItemsAccess)
local ServerPlacement = require(Server.Plots.ServerPlacement)

function PlotLoader.Load(player)
    local playerTag = "#"..player.UserId
    local plot = PlotUtility.GetPlotFromPlayer(player)
    local root = plot:WaitForChild("Root")

    local plotSize = 2 -- Change this
    local tileSize = 8-- DONT CHANGE

    local actualPlotWidth = plotSize*tileSize
    root.Transparency = 1
    root.Size = Vector3.new(actualPlotWidth,1,actualPlotWidth)
    local origin = root.Position - Vector3.new(actualPlotWidth/2+tileSize/2,0,actualPlotWidth/2+tileSize/2)

    -- Load tiles.
    for x = 1,actualPlotWidth/tileSize do
        for y = 1,actualPlotWidth/tileSize do
            local asset = AssetsDealer.GetTile("Green")
            local tile = asset.Model :: Model
            tile.Parent = plot.Tiles
            tile:PivotTo(CFrame.new(origin+Vector3.new(x*tileSize,0,y*tileSize)))
            asset:Destroy()
        end
    end
    -- Load items.
    local playerPlacedItems = ItemsAccess.GetPlacedItems(player)
    if not playerPlacedItems then return end
    for localID,data in pairs(playerPlacedItems) do
        local position = Vector3.new(data[1],data[2],data[3])
        local success,arg1 = ServerPlacement.PlaceItem(player,position,data[4],data[5],localID,nil,true)
        if not success then
            warn("Error from player's("..playerTag..") plot loading placement : "..arg1)
        end
    end
end

return PlotLoader