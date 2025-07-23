local DropHover = {}

-- -- Services --
-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local RunService = game:GetService("RunService")

-- -- Folders --
-- local Shared = ReplicatedStorage.Shared

-- -- Modules --
-- local PlacementUtility = require(Shared.Plots.PlacementUtility)
-- local AssetsDealer = require(Shared.AssetsDealer)

-- -- LocalPlayer --
-- local Player = Players.LocalPlayer
-- local Mouse = Player:GetMouse()
-- local Camera = workspace.Camera

-- -- Variables --
-- local CurrentHoveredDrop = nil
-- local CashDisplayUi = nil
-- repeat task.wait(.2) until Player:GetAttribute("Plot") and PlacementUtility.GetClientPlot()
-- local Plot = PlacementUtility.GetClientPlot()

-- -- Constants --
-- local RAYCAST_PARAMS = RaycastParams.new()
-- RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
-- RAYCAST_PARAMS.FilterDescendantsInstances = {Plot.Drops}

-- -- Functions --
-- local function getDropFromPart(part)
--     for _, drop in pairs(Plot.Drops:GetChildren()) do
--         if drop == part then
--             return drop
--         end
--     end
--     return nil
-- end

-- local function createCashDisplay(drop)
--     if CashDisplayUi then
--         CashDisplayUi:Destroy()
--     end
    
--     CashDisplayUi = AssetsDealer.GetUi("Misc/CashDisplay")
--     CashDisplayUi.Parent = drop
-- end

-- local function updateCashDisplay(drop)
--     if not CashDisplayUi then return end
    
--     local currentValue = drop:GetAttribute("CurrentValue") or 0
--     CashDisplayUi.Frame.CashLabel.Text = "$" .. tostring(currentValue)
--     CashDisplayUi.Adornee = drop
-- end

-- local function showCashDisplay(drop)
--     createCashDisplay(drop)
--     updateCashDisplay(drop)
--     CashDisplayUi.Enabled = true
-- end

-- local function hideCashDisplay()
--     if CashDisplayUi then
--         CashDisplayUi.Enabled = false
--     end
-- end

-- local function hover(drop)
--     if CurrentHoveredDrop == drop then return end
    
--     CurrentHoveredDrop = drop
--     showCashDisplay(drop)
-- end

-- local function unHover()
--     CurrentHoveredDrop = nil
--     hideCashDisplay()
-- end

-- local function update()
--     local raycast = workspace:Raycast(Camera.CFrame.Position, Mouse.UnitRay.Direction * 100, RAYCAST_PARAMS)
    
--     if raycast then
--         local part = raycast.Instance
--         if part then
--             local drop = getDropFromPart(part)
--             if drop then
--                 hover(drop)
--                 return
--             end
--         end
--     end
    
--     unHover()
-- end

-- function DropHover.Setup()
--     RunService.RenderStepped:Connect(update)
-- end

return DropHover