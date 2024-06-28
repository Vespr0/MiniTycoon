local Time = {}

function Time.GetFullTime(seconds)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    minutes = minutes - (hours * 60)
    seconds = seconds - (minutes * 60) - (hours * 60 * 60)

    return { hours = hours, minutes = minutes, seconds = seconds }
end

function Time.GetFullTimeString(seconds)
    local time = Time.GetFullTime(seconds)
    return string.format("%02d:%02d:%02d", time.hours, time.minutes, time.seconds)
end

return Time