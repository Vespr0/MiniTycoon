local ShopInfo = {}

local function getInfoFromItemName(itemName)
    for category, items in ShopInfo.Items do
        if items[itemName] then
            return items[itemName]
        end
    end
    return nil
end

function ShopInfo.GetItemShopInfo(itemName)
    local info = getInfoFromItemName(itemName)
    if not info then
        warn("Shop info not found for item: " .. itemName)
        return nil
    end

    local price = info.price
    if not price or type(price) ~= "number" or price < 0 then
        warn("Invalid or missing price for item: " .. itemName)
        return nil
    end
    local levelRequirement = info.levelRequirement
    if not levelRequirement or type(levelRequirement) ~= "number" then
        warn("Invalid or missing level requirement for item: " .. itemName)
        return nil
    end

    return info
end

function ShopInfo.CalculateDiscount(itemName, offerPrice)
    local shopInfo = ShopInfo.GetItemShopInfo(itemName)
    if not shopInfo then
        return 0, false
    end
    
    -- TODO: Decide if this makes sense or not
    -- Only show discount if item is available in market
    if not shopInfo.inMarket then
        return 0, false
    end
    
    local originalPrice = shopInfo.price
    if not originalPrice or offerPrice >= originalPrice then
        return 0, false
    end
    
    local discount = math.floor(((originalPrice - offerPrice) / originalPrice) * 100)
    return discount, discount > 0
end

ShopInfo.Items = {

    -- Droppers
    Dropper = {
        CoalMine = {
            price = 40,
            levelRequirement = 1,
            inMarket = true,
            inOffers = true,
        },

        IronMine = {
            price = 60,
            levelRequirement = 2,
            inMarket = true,
            inOffers = true,
        },

        LargeCoalMine = {
            price = 100,
            levelRequirement = 3,
            inMarket = true,
            inOffers = true
        },

        QuartzMine = {
            price = 1000,
            levelRequirement = 10,
            inMarket = false, -- Not in market, just offers
            inOffers = true
        },

        UraniumLazur = {
            price = 1500,
            levelRequirement = 20,
            inMarket = false,
            inOffers = true 
        },
    },

    -- Conveyor Belts
    Belt = {
        OldBelt = {
            price = 20,
            levelRequirement = 1,
            inMarket = true,
            inOffers = true
        },

        IceBelt = {
            price = 100,
            levelRequirement = 10,
            inMarket = false, 
            inOffers = true
        }
    },

    -- Upgraders
    Upgrader = {
        OldWasher = {
            price = 100,
            levelRequirement = 1,
            inMarket = true,
            inOffers = true
        },
        UraniumInfuser = {
            price = 1500,
            levelRequirement = 20,
            inMarket = true,
        }
    },

    -- Forge
    Forge = {
        OldForge = {
            price = 100,
            levelRequirement = 1,
            inMarket = true,
        },
    },

    -- Decorations
    Decor = {
        SmallTree = {
            price = 20,
            levelRequirement = 1,
            inMarket = true, -- Not in market, just offers
            inOffers = true,
        },
    }
}

return ShopInfo