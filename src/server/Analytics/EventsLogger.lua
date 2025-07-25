local AnalyticsService = game:GetService("AnalyticsService")

-- Modules --
local AnalyticsUtility = require(script.Parent.AnalyticsUtility)

local EventsLogger = {}

--[[
    EVENTS

    Custom events let you track metrics specific to your experience that other events do not fully capture. This includes:

    Adoption — How many users click on a specific UI component?
    User behavior — What is the most frequently used ability on each map?
    Core loop — How do kill/death ratios compare across different weapons?

    Once your experience begins tracking custom events, you'll unlock the Custom page of the Analytics dashboard on the Creator Hub. You can add up to 100 custom events to your experience.

    Docs: https://create.roblox.com/docs/production/analytics/funnel-events
-- ]]

--[[
    HOW TO USE CUSTOM FIELDS

    Docs: https://create.roblox.com/docs/production/analytics/custom-fields

    Custom events also allow breaking down on custom fields to support easier comparison between segments. For example, you can provide quest names to each event to see which ones users prefer the most, or attach player class to see if a class has a significantly higher kill/death ratio.

    You can breakdown by custom fields by using the breakdown selector.

    You should use custom fields whenever possible instead of event names, since there is a much tighter cardinality limit on event names than custom fields. Using custom fields also allows you to see visualizations of events across field values.

    For example, instead of PlantCabbage, PlantTurnip, PlantPepper as three separate events, you could have a single event with the name PlantSeed and custom field values Plant - Cabbage, Plant - Turnip, and Plant - Pepper. This way you can visualize both the total number of seeds planted as well as compare each plant in the same visualization. This also reduces your event name cardinality.
]]

-- function EventsLogger.LogEventRaw(player: Player, eventName: string, eventValue: any)
--     -- Skip analytics for admin players
--     if not AnalyticsUtility.ValidatePlayer(player) then
--         return
--     end
    
--     AnalyticsService:LogCustomEvent(
--         player,
--         eventName, -- Event name
--         eventValue -- Event value
--     )
-- end

-- -- Log item placement events
-- function EventsLogger.LogItemPlaced(player: Player, itemName: string, plotLevel: number?)
--     -- Skip analytics for admin players
--     if not AnalyticsUtility.ValidatePlayer(player) then
--         return
--     end
    
--     AnalyticsService:LogCustomEvent(
--         player,
--         "ItemPlaced",
--         AnalyticsUtility.CreateCustomFields(
--             AnalyticsUtility.FormatCustomField("Item", itemName),
--             AnalyticsUtility.FormatCustomField("PlotLevel", plotLevel or 1)
--         )
--     )
-- end

-- -- Log item removal events
-- function EventsLogger.LogItemRemoved(player: Player, itemName: string, plotLevel: number?)
--     -- Skip analytics for admin players
--     if not AnalyticsUtility.ValidatePlayer(player) then
--         return
--     end
    
--     AnalyticsService:LogCustomEvent(
--         player,
--         "ItemRemoved",
--         AnalyticsUtility.CreateCustomFields(
--             AnalyticsUtility.FormatCustomField("Item", itemName),
--             AnalyticsUtility.FormatCustomField("PlotLevel", plotLevel or 1)
--         )
--     )
-- end

-- Log plot expansion events
function EventsLogger.LogPlotExpansion(player: Player, fromLevel: number, toLevel: number)
    -- Skip analytics for admin players
    if not AnalyticsUtility.ValidatePlayer(player) then
        return
    end
    
    AnalyticsService:LogCustomEvent(
        player,
        "PlotExpansion",
        AnalyticsUtility.CreateCustomFields(
            AnalyticsUtility.FormatCustomField("FromLevel", fromLevel),
            AnalyticsUtility.FormatCustomField("ToLevel", toLevel)
        )
    )
end

return EventsLogger
