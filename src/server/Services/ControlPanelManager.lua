local ControlPanelManager = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Events = ReplicatedStorage.Events
local Shared = ReplicatedStorage.Shared

-- Modules --
-- local AssetsDealer = require(Shared.AssetsDealer)
local PlotAccess = require(Server.Data.DataAccessModules.PlotAccess)
local PlotManager = require(Server.Plots.PlotManager)
local CashAccess = require(Server.Data.DataAccessModules.CashAccess)
local PlotUtility = require(Shared.Plots.PlotUtility)
local FunnelsLogger = require(Server.Analytics.FunnelsLogger)

local function upgradeRequest(player,name)
	if not (name) then return false, `Missing arguments` end
	if not (typeof(name) == "string") then return false,`Invalid arguments` end

	local currentPlotLevel = PlotAccess.GetLevel(player)
	print(currentPlotLevel)
	local info = PlotUtility.Upgrades[name]
	local cost = PlotUtility.UpgradeCosts[name](currentPlotLevel)
	if cost then
		local isMaxxed = currentPlotLevel >= info.MaxValue 
		
		if isMaxxed then return false, `Updrade is maxxed` end
		
		local currentCash = CashAccess.GetCash(player)
		if currentCash >= cost then
			CashAccess.TakeCash(player,cost)
			PlotManager.Upgrade(player,name)
			
			print(currentPlotLevel)

			-- Funnel log for onboarding step 6
 			FunnelsLogger.LogOnboarding(player, "FirstPlotExpansion")

			return currentPlotLevel+1
		else
			return false, `Not enough cash.`
		end
	else
		return false, `Invalid request`
	end
end

function ControlPanelManager.Setup()
	Events.Upgrade.OnServerInvoke = upgradeRequest
end

return ControlPanelManager
