--!strict
local ColorUtility = {}

local function adjustColor(color: Color3, factor) : Color3
    -- Ensure the factor is within the correct range
    factor = math.clamp(factor, -1, 1)
    
    -- Lighten or darken each component
    local function adjustComponent(component)
        if factor > 0 then
            -- Lighten component
            return component + (1 - component) * factor
        else
            -- Darken component
            return component * (1 + factor)
        end
    end
    
    local newR = adjustComponent(color.R)
    local newG = adjustComponent(color.G)
    local newB = adjustComponent(color.B)
    
    return Color3.new(newR, newG, newB)
end

ColorUtility.Darken = function(color, factor)
	return adjustColor(color, factor or -0.2)
end

ColorUtility.Lighten = function(color, factor)
	return adjustColor(color, factor or 0.2)
end

return ColorUtility