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

-- local function getAllItemsCount()
--     local x = 0
--     for _,_ in pairs(ItemInfo.IDs) do
--         x += 1
--     end
--     return x
-- end

-- local allItemsCount = getAllItemsCount()

local ITEMS_POOL = {
    ["CoalMine"] = 1;
    ["AzuriteExtractor"] = 5;
    ["CrocoiteExtractor"] = 5;
    ["UraniumMine"] = 10;
    ["UraniumLazur"] = 20;
    ["BreadOven"] = 40;
}

local UTILITY_POOL = {
    ["OldBelt"] = 1;
    ["IceBelt"] = 100;
}

local SPECIAL_POOL = {
    --["SmallTree"] = 1;
    ["Obamna"] = 20;
}

local function getRandom(weights)
    return weights[math.random(1,#weights)]
end

local function getPrice(score,factor,amount)
    local difference = score-factor
    local differenceFactor

    local differenceMultiplier 
    if difference > 0 then
        differenceFactor = factor/score
        differenceMultiplier = 1 - differenceFactor
    else
        differenceFactor = math.abs(difference)/factor 
        differenceMultiplier = 1 + differenceFactor
    end

    local amountFactor = (1+amount/10) -- The more items the player has , the more a duplicate should cost.
    local delta = math.round(factor*100 * differenceMultiplier * amountFactor)
    return math.abs(delta)
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

local function getWeightsNumber(score,factor,amount)
    local diff = score-factor
    if diff <= 0 then
        return 0 
    end
    return math.clamp(((score/factor)*10)/(amount+1),0,50)
end

local function generateWeights(player,score,pool)
    local randomMultiplier = (1 + (math.random(0,100)/100)) -- To spice things up the player might get rarer things than normal if lucky enough
    score *= randomMultiplier

    local weights = {}
    for itemName,factor in pairs(pool) do
        local amount = isItemPresentInInventory(player,itemName)
        local weightsNumber = getWeightsNumber(score,factor,amount)

        while weightsNumber > 0 do
            table.insert(weights,{ItemName = itemName,Price = getPrice(score,factor,amount)})
            weightsNumber -= 1
        end
    end
    warn(weights)
    return weights
end

local function generateOffers(player,score,count,pool)
    local weights = generateWeights(player,score,pool)
    if not weights or not next(weights) then warn("Failed to generate weights") return end

    local offers = {}

    local function get(attempts)
        local random = getRandom(weights)
        if not random then warn("Failed to get random weight") return end

        if attempts <= 0 then return random end
        if offers[random.ItemName] then
            return get(attempts-1)
        else
            return random
        end
    end
    for i = 1,count do
        local offer = get(3)
        if offer then
            table.insert(offers,offer)
        end
    end

    return offers
end

function OffersUtil.GenerateOffers(player)
    if not player then warn("Player not specified or nil") return end

    local level,_ = LevelingAccess.Get(player)
    --local offersBought = StatsAccess.GetStat(player,"OffersBought")

    local score = level --+ offersBought*5

    local offers = {}

    -- 4 ITEMS
    local itemOffers = generateOffers(player,score,4,ITEMS_POOL)
    if itemOffers then
        for _,offer in pairs(itemOffers) do
            table.insert(offers,offer)
        end
    end
    -- 1 UTILITY
    local utilityOffers = generateOffers(player,score,1,UTILITY_POOL)
    if utilityOffers then
        for _,offer in pairs(utilityOffers) do
            table.insert(offers,offer)
        end
    end
    -- 1 SPECIAL
    local specialOffers = generateOffers(player,score,1,SPECIAL_POOL)
    if specialOffers then
        for _,offer in pairs(specialOffers) do
            table.insert(offers,offer)
        end
    end


    return offers
end

return OffersUtil
    