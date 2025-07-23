local AnalyticsService = game:GetService("AnalyticsService")

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

function EventsLogger.LogEventRaw(player, eventName: string, eventValue: any)
    AnalyticsService:LogCustomEvent(
        player,
        eventName, -- Event name
        eventValue -- Event value
    )
end

return EventsLogger
