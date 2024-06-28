local Cash = {}

function Cash.Format(value,decimals)
    -- Convert the number to a string and split it into integer and decimal parts
    local str = string.format("%.2f", value)
    local integerPart, decimalPart = str:match("^(%d+)%.(%d+)$")

    -- Reverse the integer part for easier processing
    local reversedInteger = integerPart:reverse()

    -- Insert dots every three digits
    local formattedInteger = reversedInteger:gsub("(%d%d%d)", "%1."):reverse()
    -- Remove any leading dot
    formattedInteger = formattedInteger:gsub("^%.", "")

    -- Combine the formatted integer part with the decimal part
    if decimals then
        decimalPart = "," .. decimalPart
    else
        decimalPart = ""
    end

    local formattedNumber = "$ " .. formattedInteger .. decimalPart

    return formattedNumber
end

return Cash