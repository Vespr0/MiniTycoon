local TilingTest = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
-- Modules
local TiliingUtility = require(Shared.Plots.TilingUtility)
local PlotUtility = require(Shared.Plots.PlotUtility)

TilingTest.Enabled = false

function TilingTest.Run()
    -- Debug generation by generating and rendering tiles
    local tilesPerSide = PlotUtility.MaxPlotWidth
    local seed = os.time() -- Use current time as seed for randomness
    local tiles = TiliingUtility.GenerateTiles(tilesPerSide, seed)

    local function place(positionX,positionY,color)
        local part = Instance.new("Part")
        part.Size = Vector3.new(1, 1, 1)
        part.Anchored = true
        part.Parent = ServerScriptService
        part.Position = Vector3.new(positionX, 100, positionY) -- Position the part above the ground
        part.Color = color or Color3.new(0, 0, 0) --
        part.Parent = workspace -- Place the part in the workspace for visibility
        return part
    end

    for x = 1, tilesPerSide do
        task.wait() -- Yield to avoid freezing the server
        for y = 1, tilesPerSide do
            local tile = tiles[x][y]
            -- Print emojis
            if tile.assetName == "Grass" then
                place(x, y, Color3.fromRGB(0, 255, 0)) -- Green color for grass
            elseif tile.assetName == "Sand" then
                place(x, y, Color3.fromRGB(255, 255, 0)) -- Yellow color for sand
            elseif tile.assetName == "Water" then
                place(x, y, Color3.fromRGB(0, 0, 255)) -- Blue color for water
            elseif tile.assetName == "Rock" then
                place(x, y, Color3.fromRGB(128, 128, 128)) -- Gray color for rock
            else
                warn("Unknown tile asset name: " .. tile.assetName)
            end
        end
    end
end

return TilingTest