local PlotAccess = {}

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local DataUtility = DataAccess.DataUtility

function PlotAccess.SetLevel(...)
	local player, level = DataAccess.GetParameters(...)
	if not (player and level) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    -- Set value.
	dataStore.Value.Plot.PlotLevel = level
	DataAccess.PlayerDataChanged:Fire(player,"Upgrade","PlotLevel",level)
end

function PlotAccess.GetLevel(...)
    local player = DataAccess.GetParameters(...)
	if not player then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
	return dataStore.Value.Plot.PlotLevel
end

return PlotAccess
