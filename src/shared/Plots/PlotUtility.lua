local PlotUtility = {}

local Plots = workspace:WaitForChild("Plots")

PlotUtility.MaxPlotWidth = 100

PlotUtility.Upgrades = {
	PlotLevel = {
		DisplayName = "Plot Level";
		Description = "<b>Expands</b> your plot and increases the <b>part limit</b>";
		MaxValue = 10;
	}	
}

function PlotUtility.GetActualPlotWidth(plotLevel: number): number
	local startBonus = 10
	-- Max size ignoring start bonus
	local maxWidth = PlotUtility.MaxPlotWidth - startBonus
	return plotLevel * (maxWidth / PlotUtility.Upgrades.PlotLevel.MaxValue) + startBonus - 0.5
end

function PlotUtility.GetMaxPartsFromPlotLevel(plotLevel: number)
	return 20*plotLevel
end

PlotUtility.UpgradeCosts = {
	PlotLevel = function(plotLevel)
		return math.round(((plotLevel * 200)^2)/10)
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

	return nil
end

function PlotUtility.DoesPlayerOwnPlot(player,plot)
	if not player then
		error("Player is missing or nil.")
	end
	local plotName = player:GetAttribute("Plot")
	if plotName then
		return plot.Name == plotName
	end

	return nil
end

function PlotUtility.WaitForPlotToLoad(plot)
	local start = os.clock()
	local timeout 
	repeat
		task.wait()
		timeout = os.clock()-start > 5
	until plot:GetAttribute("Loaded") or timeout

	if timeout then
		error(`Plot "{plot.Name}" took too long to load.`)
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