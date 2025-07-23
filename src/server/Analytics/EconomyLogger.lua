local AnalyticsService = game:GetService("AnalyticsService")

local EconomyLogger = {}

--[[
    ECONOMY: 

    Economy events let you track your in-experience economy, such as:

    Top sinks — What do users spend in-experience resources on?
    Top sources — Where do users earn resources?
    Average wallet balance — How much resources are users holding?

    Once your experience begins tracking Economy events, you'll unlock the
    Economy page of the Analytics dashboard on the Creator Hub.

    Docs: https://create.roblox.com/docs/production/analytics/economy-events
-- ]]

local CASH_CURRENCY_STRING = "Cash"

-- function EconomyLogger.LogEconomyRaw(player: Player, economyFlowType: string, trasactionType: string, amount: number, endingBalance: number)
--     if not Enum.AnalyticsEconomyFlowType:FromName(economyFlowType) then
--         warn(`Invalid economy flow type: {economyFlowType}`)
--         return
--     end
--     --[[
--         Economy flow types

--         Source - Resources are added to the economy, e.g. earning cash.
--         Sink - Resources are removed from the economy, e.g. spending cash.
        

--     ]]
--     if not Enum.AnalyticsEconomyTransactionType:FromName(trasactionType) then
--         warn(`Invalid economy transaction type: {trasactionType}`)
--         return
--     end
--     --[[    
--         Transaction types
        
--         IAP (source) - In-app purchases exchanging Robux for resources, e.g. starter pack.
--         TimedReward (source) - Earn resources on a schedule, e.g. daily bonus.
--         Onboarding (source) - Get resources when getting started, e.g. welcome bonus.
--         Shop (source or sink) - Trade resources in the shop, e.g. item purchase.
--         Gameplay (source or sink) - Earn or spend resources from gameplay, e.g. quest completion.
--         ContextualPurchase (sink) - Spend resources on a context-specific impulse, e.g. extra lives.
--     ]]

--     -- Log a one-time event)

--     local transactionTypeEnum = Enum.AnalyticsEconomyTransactionType[trasactionType]
--     AnalyticsService:LogEconomyEvent(
--         player,
--         Enum.AnalyticsEconomyFlowType:FromName(economyFlowType),
--         CASH_CURRENCY_STRING, -- Currency name
--         amount, -- Amount
--         endingBalance, -- Balance
--         transactionTypeEnum.Name -- Transaction type name
--     )
-- end

-- function EconomyLogger.LogEarnedCash(player: Player, trasactionType: string, amount: number, endingBalance: number)
--     EconomyLogger.LogEconomyRaw(player, "Source", trasactionType, amount, 0)
-- end


--[[

local AnalyticsService = game:GetService("AnalyticsService")


AnalyticsService:LogEconomyEvent(

    player,

    Enum.AnalyticsEconomyFlowType.Sink,

    "Coins", -- Currency name

    80, -- Cost

    20, -- Balance after transaction

    Enum.AnalyticsEconomyTransactionType.Shop.Name,

    "Obsidian Sword", -- Item SKU

    {

	[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "Category - Weapon",

	[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = "Class - Warrior",

	[Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = "Level - 10",

    } -- Custom field dictionary table

)
]]

export type ShopPurchaseType = "Market" | "Offers"

function EconomyLogger.LogShopPurchase(player: Player, itemName: string, shopPurchaseType: ShopPurchaseType, cost: number, endingBalance: number)
    if shopPurchaseType ~= "Market" and shopPurchaseType ~= "Offers" then
        warn(`Invalid shop purchase type: {shopPurchaseType}`)
        return
    end

    AnalyticsService:LogEconomyEvent(
        player,
        Enum.AnalyticsEconomyFlowType.Sink,
        CASH_CURRENCY_STRING,
        cost,
        endingBalance,
        Enum.AnalyticsEconomyTransactionType.Shop.Name,
        itemName,

        -- Custom fields
        {
            [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = `ShopPurchaseType - {shopPurchaseType}`
        }
    )
end

--[[
    TODO

    Batch call system for ore sells

    Every time a specific product is sold , we add to a list the earnings and the product name (earnings for the same product stack),

    every x seconds we send the requests.
--]]

-- function EconomyLogger.LogSingleDropSell(player: Player, earnings: number, endingBalance: number)

return EconomyLogger
