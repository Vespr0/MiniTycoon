local LevelingUtil = {}

function LevelingUtil.GetExpForLevel(level)
    return (level^1.5 / 2) * 100 + 100
end

function LevelingUtil.GetLevelAndExpFromExpGain(startingLevel,originalExp,gainedExp)
    local expToLevelUp = LevelingUtil.GetExpForLevel(startingLevel+1)
    local expSum = originalExp+gainedExp
    local isLevelUp = (expSum) >= expToLevelUp

    if isLevelUp then
        local extraExp = expSum-expToLevelUp
        return LevelingUtil.GetLevelAndExpFromExpGain(startingLevel+1, 0, extraExp)
    else
        return startingLevel,expSum
    end
end

return LevelingUtil