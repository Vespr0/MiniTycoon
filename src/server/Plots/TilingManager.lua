local TilingManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Events = ReplicatedStorage.Events

local ReplicateTiling = Events.ReplicateTiling

local TilingUtility = require(ReplicatedStorage.Shared.Plots.TilingUtility)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

TilingManager.TilingInfo = {} 

function TilingManager.ResizeRoot(root: BasePart, plotLevel: number)
    local actualPlotWidth = TilingUtility.GetActualPlotWidth(plotLevel)
    root.Size = Vector3.new(actualPlotWidth, 1, actualPlotWidth)
end

--- Loads and tiles the plot root with tiles.
function TilingManager.GenerateTiling(userID: number, root: BasePart, plotName: string, plotLevel: number)
    local seed = userID;

    warn(seed)
    ReplicateTiling:FireAllClients(plotName, seed)

    TilingManager.TilingInfo[plotName] = {
        tiles = TilingUtility.GenerateTiles(TilingUtility.MaxPlotWidth/GameConfig.TileSize, seed),
        seed = seed,
        root = root,
    }
end

function TilingManager.Setup()
    -- Replicate existing tiling info to players when they join.
    Players.PlayerAdded:Connect(function(player)
        for _,plot in workspace.Plots:GetChildren() do
            if plot:GetAttribute("OwnerID") ~= 0 then
                local info = TilingManager.TilingInfo[plot.Name]

                local seed = info.seed
                warn(seed)
                ReplicateTiling:FireClient(player, plot.Name, seed)
            end
        end
    end)
end

return TilingManager
