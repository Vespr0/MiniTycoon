local AnalyticsService = game:GetService("AnalyticsService")

local FunnelsLogger = {}

--[[
    FUNNELS

    Funnel events let you track your user's progress through key stages of your experience. This includes:
    
    Onboarding - Where do users drop off when getting started with your experience?
    Progression - Where do users stop advancing through your experience?
    Shop - Where do users abandon purchases?

    Once your experience begins tracking Funnel events, you'll unlock the Funnel page of the Analytics dashboard on the Creator Hub. You can add tabs to the dashboard for up to ten funnels.

    Docs: https://create.roblox.com/docs/production/analytics/funnel-events
-- ]]

FunnelsLogger.OnboardingSteps = {
    FirstPlayed = 1,
    FirstItemPlaced = 2,
    FirstCashEarned = 3,
    FirstOfferPurchase = 4,
    FirstMarketPurchase = 5,
    FirstPlotExpansion = 6,
}

function FunnelsLogger.LogOnboarding(player: Player, eventName: string)
    if not FunnelsLogger.OnboardingSteps[eventName] then
        warn("Invalid onboarding event name: " .. tostring(eventName))
        return
    end

    local step = FunnelsLogger.OnboardingSteps[eventName]
    -- Log a one-time event
    AnalyticsService:LogOnboardingFunnelStepEvent(
        player, step, eventName
    )
end

return FunnelsLogger
