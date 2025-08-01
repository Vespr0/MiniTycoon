local OnboardingAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local FunnelsLogger = require(script.Parent.Parent.Parent.Analytics.FunnelsLogger)

-- Check if an onboarding step has been completed
function OnboardingAccess.HasCompleted(...)
	local player, stepName = DataAccess.GetParameters(...)
	if not (player and stepName) then return false end

    local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
    if not dataStore then return false end
    
    return dataStore.Value.Onboarding[stepName] or false
end

-- Mark an onboarding step as completed and log it
function OnboardingAccess.Complete(...)
	local player, stepName = DataAccess.GetParameters(...)
	if not (player and stepName) then return end
    
    -- Validate step name
    if not FunnelsLogger.OnboardingSteps[stepName] then
        warn("Invalid onboarding step name: " .. tostring(stepName))
        return
    end

    local dataStore = DataAccess.AccessDataStore(nil, player.UserId)
    if not dataStore then return end
    
    -- Only log and mark if not already completed
    if not dataStore.Value.Onboarding[stepName] then
        dataStore.Value.Onboarding[stepName] = true
        FunnelsLogger.LogOnboarding(player, stepName)
        DataAccess.PlayerDataChanged:Fire(player, "Onboarding", stepName)
    end
end

-- Check level-based onboarding steps
function OnboardingAccess.CheckLevelSteps(...)
	local player, level = DataAccess.GetParameters(...)
	if not (player and level) then return end
    
    if level >= 25 then
        OnboardingAccess.Complete(player, "ReachedLevel25")
    end
    
    if level >= 50 then
        OnboardingAccess.Complete(player, "ReachedLevel50")
    end
    
    if level >= 100 then
        OnboardingAccess.Complete(player, "ReachedLevel100")
    end
end

function OnboardingAccess.Init()
    -- Nothing to initialize here
end

return OnboardingAccess