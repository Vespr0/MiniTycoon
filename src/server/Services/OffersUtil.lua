
local OffersUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server

-- Modules --
local LevelingAccess = require(Server.Data.DataAccessModules.LevelingAccess)
local StatsAccess = require(Server.Data.DataAccessModules.StatsAccess)
local ItemInfo = require(Shared.Items.ItemInfo)
local ItemsAccess = require(Server.Data.DataAccessModules.ItemsAccess)
local ItemUtility = require(Shared.Items.ItemUtility)
local ShopInfo = require(Shared.Services.ShopInfo)

local CurrentRandom = nil

local OFFER_DISCOUNT_MIN = 0.2 -- Minimum discount off market price
local OFFER_DISCOUNT_MAX = 0.4 -- Maximum discount off market price
local RANDOM_VARIATION = OFFER_DISCOUNT_MIN/2    -- Random variation

-- Dynamically build the offers pool from ShopInfo.Items where inOffers is true
local function getOffersPool()
    local pool = {}
    for category, items in ShopInfo.Items do
        for itemName, info in items do
            if info.inOffers then
                pool[itemName] = {
                    levelRequirement = info.levelRequirement or 1,
                    luckFactor = info.luckFactor or 1,
                    category = category
                }
            end
        end
    end
    return pool
end

local function isItemPresentInInventory(player,itemName)
    local amount = 0
    -- Storage
    local storageItemAmount = ItemsAccess.GetStorageItem(player,itemName)
    if storageItemAmount then amount += storageItemAmount end
    -- Placed
    local placedItems = ItemsAccess.GetPlacedItems(player)
    if not placedItems then return end
    for _,item in pairs(placedItems) do
        if item[4] == itemName then
            amount += 1
        end
    end
    return amount
end

local function calculateOfferPrice(basePrice, level, amount)
    -- Always apply a discount to market price
    local discount = CurrentRandom:NextNumber(OFFER_DISCOUNT_MIN, OFFER_DISCOUNT_MAX)
    local offerPrice = basePrice * (1 - discount)

    -- Add some randomness (e.g., +/- RANDOM_VARIATION)
    local randomVariation = CurrentRandom:NextNumber(1 - RANDOM_VARIATION, 1 + RANDOM_VARIATION)
    offerPrice = offerPrice * randomVariation

    -- Ensure offer price is always less than market price, at least 1
    offerPrice = math.floor(math.clamp(offerPrice, 1, basePrice - 1))
    return offerPrice
end

local function getWeightsNumber(level,levelRequirement,luckFactor,amount)
    -- Allow items where player level >= levelRequirement
    local diff = level - levelRequirement
    if diff < 0 then
        return 0
    end
    -- Default luckFactor to 1 if missing
    luckFactor = luckFactor or 1
    local weights = (level * 10) / (amount + 1)
    local lucky = CurrentRandom:NextNumber() <= luckFactor
    if not lucky then return 0 end
    return math.clamp(weights, 1, 50) -- always at least 1 if eligible
end

local function generateWeights(player, level, pool)
    local randomMultiplier = (1 + (math.random(0,100)/100))
    level *= randomMultiplier

    local weights = {}
    for itemName, factors in pool do
        local levelRequirement = factors.levelRequirement
        local luckFactor = factors.luckFactor

        -- Item config
        -- local itemConfig = ItemUtility.GetItemConfig(itemName)
        -- Shop info
        local shopInfo = ShopInfo.GetItemShopInfo(itemName)
        local basePrice = shopInfo.price

        local amount = isItemPresentInInventory(player, itemName)
        local weight = getWeightsNumber(level, levelRequirement, luckFactor, amount)
        print(`Generating weights for {itemName}: basePrice: {basePrice} owned: {amount} -  Weight: {weight}`)
        if weight > 0 then
            table.insert(weights, {
                ItemName = itemName,
                Price = calculateOfferPrice(basePrice, level, amount),
                Weight = weight,
                Category = factors.category
            })
        end
    end
    return weights
end

local function weightedRandom(weights)
    local totalWeight = 0
    for _, entry in ipairs(weights) do
        totalWeight = totalWeight + entry.Weight
    end
    if totalWeight == 0 then return nil end
    local pick = CurrentRandom:NextNumber(0, totalWeight)
    local cumulative = 0
    for _, entry in ipairs(weights) do
        cumulative = cumulative + entry.Weight
        if pick <= cumulative then
            return entry
        end
    end
    return weights[#weights] -- fallback
end

local function generateOffers(player, level, count, pool)
    CurrentRandom = Random.new(workspace:GetServerTimeNow())

    local weights = generateWeights(player, level, pool)
    if not weights or not next(weights) then
        warn("Failed to generate weights")
        return
    end

    local offers = {}
    local picked = {}

    for i = 1, count do
        -- Remove already picked items from weights
        local available = {}
        for _, entry in ipairs(weights) do
            if not picked[entry.ItemName] then
                table.insert(available, entry)
            end
        end
        if #available == 0 then break end
        local offer = weightedRandom(available)
        if offer then
            table.insert(offers, offer)
            picked[offer.ItemName] = true
        end
    end

    return offers
end 

function OffersUtil.GenerateOffers(player)
    if not player then warn("Player not specified or nil") return end

    local level,_ = LevelingAccess.Get(player)
    local offers = {}

    local offersPool = getOffersPool()
    -- You can adjust the number of offers as needed
    local offerCount = 8
    local generatedOffers = generateOffers(player, level, offerCount, offersPool)
    if generatedOffers then
        for _, offer in pairs(generatedOffers) do
            table.insert(offers, offer)
        end
    end

    return offers
end

return OffersUtil
    