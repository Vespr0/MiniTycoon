local MarketManager = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Events = ReplicatedStorage.Events
local Shared = ReplicatedStorage.Shared

-- Modules --
local ItemsAccess = require(Server.Data.DataAccessModules.ItemsAccess)
local CashAccess = require(Server.Data.DataAccessModules.CashAccess)
local LevelingAccess = require(Server.Data.DataAccessModules.LevelingAccess)
local OnboardingAccess = require(Server.Data.DataAccessModules.OnboardingAccess)
local ShopInfo = require(Shared.Services.ShopInfo)
local EconomyLogger = require(Server.Analytics.EconomyLogger)

local function buyMarketItem(player, args)
	local itemName = args and args.itemName
	if not player or not itemName then return false, "Invalid arguments." end

	local info = ShopInfo.GetItemShopInfo(itemName)
	if not info or not info.inMarket then return false, "Item not found in market." end

	local playerLevel = LevelingAccess.Get(player)
	if playerLevel < info.levelRequirement then return false, "Level too low for this item." end

	local price = info.price
	local cash = CashAccess.GetCash(player)
	if cash < price then return false, "Not enough cash." end

	-- Take cash and give item
	CashAccess.TakeCash(player, price)
	ItemsAccess.GiveStorageItems(player, itemName, 1)
	LevelingAccess.GiveExp(player, price)

	-- Funnel log for onboarding step
	OnboardingAccess.Complete(player, "FirstMarketPurchase")

	-- Log economy shop purchase
	local endingCash = CashAccess.GetCash(player) - price
	EconomyLogger.LogShopPurchase(player, itemName, "Market", price, endingCash)

	return true
end

local function onBuyRequest(player, args)
	return buyMarketItem(player, args)
end

function MarketManager.Setup()
	Events.Market.OnServerInvoke = onBuyRequest
end

return MarketManager
