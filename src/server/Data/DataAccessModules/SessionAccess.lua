local SessionAccess = {}

-- Services --
local Players = game:GetService("Players")

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local OnboardingAccess = require(script.Parent.OnboardingAccess)

local function setSessionVariable(player, variable, value)
	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then
		return
	end

	dataStore.Value.Session[variable] = value or os.time()
end

local function hasPlayerPlayedBefore(player)
	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then
		return
	end

	local firstPlayed = dataStore.Value.Session["FirstPlayed"]
	return not (firstPlayed == nil or firstPlayed == 0)
end

local function giveFirstPlayedResources(player)
	-- Give starter cash
	local CashAccess = require(script.Parent.CashAccess)
	CashAccess.GiveCash(player, 50)
	
	-- Log onboarding cash
	local EconomyLogger = require(script.Parent.Parent.Parent.Analytics.EconomyLogger)
	local endingCash = CashAccess.GetCash(player)
	EconomyLogger.LogOnboardingCash(player, 50, endingCash)

	-- Give starter items
	local ItemsAccess = require(script.Parent.ItemsAccess)
	ItemsAccess.GiveStorageItems(player, "CoalMine", 1)
	ItemsAccess.GiveStorageItems(player, "OldBelt", 5)
	ItemsAccess.GiveStorageItems(player, "OldForge", 1)
end

function SessionAccess.SetFirstPlayed(...)
	local player = DataAccess.GetParameters(...)
	if not player then
		return
	end

	setSessionVariable(player, "FirstPlayed")
	warn(player.UserId .. " first played: " .. os.date("%c"))

	-- Give starter resources to new players
	giveFirstPlayedResources(player)

	-- Log onboarding step
	OnboardingAccess.Complete(player, "FirstPlayed")

	-- Update
	DataAccess.PlayerDataChanged:Fire(player, "FirstPlayed", os.time())
end

function SessionAccess.SetLastPlayed(...)
	local player = DataAccess.GetParameters(...)
	if not player then
		return
	end

	setSessionVariable(player, "LastPlayed")
	--warn(player.UserId.." last played: "..os.date("%c"))

	-- Update
	DataAccess.PlayerDataChanged:Fire(player, "LastPlayed", os.time())
end

function SessionAccess.UpdateTotalPlayTime(...)
	local player = DataAccess.GetParameters(...)
	if not player then
		return
	end

	local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
	if not dataStore then
		return
	end

	local addedPlayTime = os.time() - dataStore.Value.Session["LastPlayed"]

	dataStore.Value.Session["TimePlayed"] += addedPlayTime
	--warn("Total Play Time: "..dataStore.Value.Session["TimePlayed"].. ". It was incremented by "..addedPlayTime)

	-- Update
	DataAccess.PlayerDataChanged:Fire(player, "TimePlayed", addedPlayTime)
end

function SessionAccess.Setup()
	Players.PlayerAdded:Connect(function(player)
		if not hasPlayerPlayedBefore(player) then
			SessionAccess.SetFirstPlayed(player)
		end
		SessionAccess.SetLastPlayed(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		SessionAccess.UpdateTotalPlayTime(player)
	end)
end

return SessionAccess
