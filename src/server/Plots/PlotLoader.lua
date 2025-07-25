local PlotLoader = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")
-- Modules --
local PlotUtility = require(Shared.Plots.PlotUtility)
local AssetsDealer = require(ReplicatedStorage.Shared.AssetsDealer)
local ItemsAccess = require(Server.Data.DataAccessModules.ItemsAccess)
local ServerPlacement = require(Server.Plots.ServerPlacement)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlotAccess = require(Server.Data.DataAccessModules.PlotAccess)
local TilingManager = require(Server.Plots.TilingManager)

local function getPlotInfo(player)
	local playerTag = "#" .. player.UserId
	local plot = PlotUtility.GetPlotFromPlayer(player)
	local root = plot:WaitForChild("Root")
	local plotLevel = PlotAccess.GetLevel(player)

	return plot, root, playerTag, plotLevel
end

-- Resize the plot, this is fired once a plot upgrade is purchased.
function PlotLoader.Resize(player)
	local plot, root, _, plotLevel = getPlotInfo(player)
	plot:SetAttribute("Level", plotLevel)

	TilingManager.Resize(root, plotLevel)
end

-- Resize the plot and load the items, this should be fired when the player joins for the first time.
function PlotLoader.Load(player)
	local plot, root, playerTag, plotLevel = getPlotInfo(player)

	plot:SetAttribute("Level", plotLevel)
	TilingManager.Resize(root, plotLevel)
	TilingManager.GenerateTiling(player.UserId, root, plot.Name, plotLevel)

	-- Load items.
	local playerPlacedItems = ItemsAccess.GetPlacedItems(player)
	if not playerPlacedItems then
		return
	end
	for localID, data in pairs(playerPlacedItems) do
		local localPosition = Vector3.new(data[1], data[2], data[3])
		local absolutePosition = root.Position + localPosition
		local success, arg1 = ServerPlacement.PlaceItem(player, absolutePosition, data[4], data[5], localID, nil, true)
		if not success then
			warn("Error from player's(" .. playerTag .. ") plot loading placement : " .. arg1)
        else
            print("Successful placement of ".. localID)
		end
	end
end

return PlotLoader
