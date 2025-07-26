local TilingManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Events = ReplicatedStorage.Events

local ReplicateTiling = Events.ReplicateTiling
local ReplicateBorder = Events.ReplicateBorder

local TilingUtility = require(ReplicatedStorage.Shared.Plots.TilingUtility)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlotUtility = require(ReplicatedStorage.Shared.Plots.PlotUtility)

TilingManager.TilingInfo = {} 

function TilingManager.Resize(root: BasePart, plotLevel: number)
    local actualPlotWidth = TilingUtility.GetActualPlotWidth(plotLevel)
    root.Size = Vector3.new(actualPlotWidth, 1, actualPlotWidth)

    ReplicateBorder:FireAllClients(root)
end

--- Loads and tiles the plot root with tiles.
function TilingManager.GenerateTiling(userID: number, root: BasePart, plotName: string, plotLevel: number)
    local seed = userID;

    ReplicateTiling:FireAllClients(plotName, seed)

    TilingManager.TilingInfo[plotName] = {
        tiles = TilingUtility.GenerateTiles(seed),
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
                ReplicateTiling:FireClient(player, plot.Name, seed)
                ReplicateBorder:FireClient(player, info.root)
            end
        end
    end)
end

return TilingManager
