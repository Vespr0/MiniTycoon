local PlotUtility = {}

local Plots = workspace:WaitForChild("Plots")

PlotUtility.Upgrades = {
	PlotLevel = {
		DisplayName = "Plot Level";
		Description = "Expands your plot";
		MaxValue = 5;
	}	
}

PlotUtility.UpgradeCosts = {
	PlotLevel = function(currentPlotLevel)
		return math.round(((currentPlotLevel * 100)^2)/10)
	end,
}

function PlotUtility.GetPlotFromPlayer(player)
	if not player then
		error("Player is missing or nil.")
	end
	local plotName = player:GetAttribute("Plot")
	if plotName then
		return Plots[plotName]
	end
end

function PlotUtility.DoesPlayerOwnPlot(player,plot)
	if not player then
		error("Player is missing or nil.")
	end
	local plotName = player:GetAttribute("Plot")
	if plotName then
		return plot.Name == plotName
	end
end

function PlotUtility.GetPart(plot,partID)
	if not plot then
		error("Plot is missing or nil.")
	end
	if not partID then
		error("PartID is missing or nil.")
	end
	local drops = plot.Drops
	for _,drop in pairs(drops:GetChildren()) do
		local d_partID = drop:GetAttribute("PartID")
		if d_partID == partID then
			return drop
		end
	end
	return nil
end

function PlotUtility.FindAvaiablePlot()
	for _,Plot in pairs(Plots:GetChildren()) do
		if Plot:GetAttribute("OwnerID") == 0 then
			return Plot.Name
		end
	end
	error("No avaiable plot was found.")
end

return PlotUtility