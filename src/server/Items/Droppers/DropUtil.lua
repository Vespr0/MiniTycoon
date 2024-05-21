local DropUtil = {}

local boostTypes = {
    "Additive","Multiplicative"
}

function DropUtil.CalculateBoost(originalValue,type,value)
    if type == "Additive" then
        return originalValue+value
    elseif type == "Multiplicative" then
        return originalValue*value
    end
    warn("``".. type .."`` is not a valid boost type")
    return originalValue
end

return DropUtil