local BadgeManager = {}

local BadgeService = game:GetService("BadgeService")

local BADGES = {
    Welcome = 4076505648012702;
}

-- Get badge id from name
function BadgeManager.GetBadgeId(name)
    local badgeId = BADGES[name]
    assert(badgeId,`Badge not found`)
    return badgeId
end

function BadgeManager.Award(player,name,r)
    r = r or 4
    if r < 0 then
        return
end

    local badgeId = BADGES[name]
    assert(badgeId,`Badge not found`)
    local success, badgeInfo = pcall(BadgeService.GetBadgeInfoAsync, BadgeService, badgeId)

    if success then
        -- Confirm that badge can be awarded
        if badgeInfo.IsEnabled then
            -- Award badge
            local awarded, errorMessage = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badgeId)
            if not awarded then
                warn("Error while awarding badge:", errorMessage)
                task.spawn(function()
                    task.wait(3)
                    BadgeService.AwardBadge(player,name,r-1)
                end)
            else
                -- Badge awarded successfully
                print(`Badge "{name}" awarded to {player.Name} (Could've been already awarded)`)
            end
        end 
    else
        warn("Error while fetching badge info")
    end

end

return BadgeManager