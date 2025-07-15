local AnalyticsService = game:GetService("AnalyticsService")

--[[
    Funnel events let you track your user's progress through key stages of your experience. This includes:
    
    Onboarding - Where do users drop off when getting started with your experience?
    Progression - Where do users stop advancing through your experience?
    Shop - Where do users abandon purchases?

    Once your experience begins tracking Funnel events, you'll unlock the Funnel page of the Analytics dashboard on the Creator Hub. You can add tabs to the dashboard for up to ten funnels.

    Docs: https://create.roblox.com/docs/production/analytics/funnel-events
]]


local FunnelManager = {}

local

function FunnelManager.LogOnboarding(eventName: string, properties: { [string]: any }?)
    -- Log a one-time event
    AnalyticsService:ReportFunnelEvent(eventName, properties)
end