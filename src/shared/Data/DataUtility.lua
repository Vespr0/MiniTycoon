local DataUtility = {}

local RunService = game:GetService("RunService")

--[[

Data scopes:

2023:

25 Sep - 25 Jun ["Player#T00"];

2024

25 Jun - ?? ?? ["Player#0"];

2025

?? ?? - ?? ?? ["Dev#3"];


--]]

local PLAYER_DATA_SCOPE = (RunService:IsStudio() and "Studio#0" or "Dev#3")
local DATA_SCOPES = {
	Player = PLAYER_DATA_SCOPE,
}

function DataUtility.GetDataScope(name)
	return DATA_SCOPES[name]
end

return DataUtility
