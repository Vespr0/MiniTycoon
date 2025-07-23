local DropUtil = {}

local _boostTypes = {
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

function DropUtil.GetDistanceToPart(dropInstance, part)
    return (dropInstance.Position - part.Position).Magnitude
end

-- Check if the upgraders are close enough to afford calculating complex collisions.
function DropUtil.GetPotentialUpgraders(dropInstance, plot, boosts)
    local items = plot.Items

    local closeUpgraders = {}
    for _,item in pairs(items:GetChildren()) do
        if item:GetAttribute("ItemType") == "Upgrader" then
            local localID = item:GetAttribute("LocalID")
            if closeUpgraders[localID] then
                continue
            end
            if boosts[localID] then
                continue
            end

            local upgrader = item:FindFirstChild("Upgrader")
            if upgrader then
                local dist = DropUtil.GetDistanceToPart(dropInstance, upgrader)
                local upgraderBiggestAxis = math.max(upgrader.Size.X,upgrader.Size.Y,upgrader.Size.Z)
                if dist > upgraderBiggestAxis then
                    continue
                end
                closeUpgraders[localID] = upgrader
            else
                warn("Missing upgrader part in upgrader item: "..item.Name)
            end
        end
    end

    return closeUpgraders
end

function DropUtil.ProcessUpgraders(dropInstance, plot, boosts)
    local upgraders = DropUtil.GetPotentialUpgraders(dropInstance, plot, boosts)
    local newBoosts = {}
    
    if next(upgraders) then
        for localID,upgrader in pairs(upgraders) do
            local overlapParams = OverlapParams.new()
            overlapParams.FilterType = Enum.RaycastFilterType.Include
            overlapParams.FilterDescendantsInstances = {dropInstance}
            local results = workspace:GetPartBoundsInBox(upgrader.CFrame,upgrader.Size,overlapParams)

            if results and results[1] == dropInstance then
                local boostType = upgrader:GetAttribute("BoostType")
                local boostValue = upgrader:GetAttribute("BoostValue")
                newBoosts[localID] = {type = boostType, value = boostValue}
            end
        end
    end
    
    return newBoosts
end

return DropUtil