local PlotUtility = {}

local Plots = workspace:WaitForChild("Plots")

function PlotUtility.GetPlotFromPlayer(player)
	if not player then
		error("Player is missing or nil.")
	end
	local plotName = player:GetAttribute("Plot")
	if plotName then
		return Plots[plotName]
	end
end

function PlotUtility.DoesPlayerOwnPlot(player,Plot)
	if not player then
		error("Player is missing or nil.")
	end
	local plotName = player:GetAttribute("Plot")
	if plotName then
		return Plot.Name == plotName
	end
end

function PlotUtility.FindAvaiablePlot()
	for _,Plot in pairs(Plots:GetChildren()) do
		if Plot:GetAttribute("Owner") == 0 then
			return Plot.Name
		end
	end
	error("No avaiable plot was found.")
end

return PlotUtility