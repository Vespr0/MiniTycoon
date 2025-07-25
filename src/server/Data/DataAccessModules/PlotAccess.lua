local PlotAccess = {}

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local DataUtility = DataAccess.DataUtility

function PlotAccess.SetLevel(...)
	local player, level = DataAccess.GetParameters(...)
	if not (player and level) then
		return
	end

	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then
		return
	end

	-- Get current level for analytics
	local currentLevel = dataStore.Value.Plot.PlotLevel

	-- Set value.
	dataStore.Value.Plot.PlotLevel = level
	DataAccess.PlayerDataChanged:Fire(player, "Upgrade", "PlotLevel", level)

	-- Log plot expansion analytics (only if it's actually an upgrade)
	if level > currentLevel then
		local EventsLogger = require(script.Parent.Parent.Parent.Analytics.EventsLogger)
		EventsLogger.LogPlotExpansion(player, currentLevel, level)
	end
end

function PlotAccess.GetLevel(...)
	local player = DataAccess.GetParameters(...)
	if not player then
		return
	end

	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then
		return
	end
	return dataStore.Value.Plot.PlotLevel
end

return PlotAccess
