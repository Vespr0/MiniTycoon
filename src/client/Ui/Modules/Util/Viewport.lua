
local ViewportUtil = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetDealer = require(ReplicatedStorage.Shared.AssetsDealer)

local function createViewportFrame(zIndex: number?)
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.fromScale(1,1)
    viewport.Position = UDim2.fromScale(0.5,0.5)
    viewport.AnchorPoint = Vector2.new(0.5,0.5)
    viewport.BackgroundTransparency = 1
    viewport.Ambient = Color3.fromRGB(177, 187, 209)
    viewport.LightColor = Color3.fromRGB(178, 161, 182)
    viewport.LightDirection = Vector3.new(-0.4, -.8, 0)
    viewport.ZIndex = zIndex or 5
    return viewport
end

local function setupModelAndCamera(viewport, model)
    model.Parent = viewport
    local origin = Vector3.new(0,0,0)
    model:PivotTo(CFrame.lookAt(origin, origin+Vector3.xAxis))

    local bounds = model:GetExtentsSize()
    local maxAxis = math.max(bounds.X, bounds.Z)
    local minAxis = math.min(bounds.X, bounds.Z)
    local distanceBias = 1.5
    local distance = distanceBias + (minAxis+maxAxis)/2

    local y = bounds.Y 
    local height = y < 2 and y+distanceBias*2 or y+distanceBias

    local cameraOrigin = origin + Vector3.new(distance,height,distance)
    local camera = Instance.new("Camera")
    camera.Parent = viewport
    camera.CFrame = CFrame.lookAt(cameraOrigin, origin+Vector3.yAxis*distanceBias/2)
    camera.FieldOfView = 40
    viewport.CurrentCamera = camera
end

function ViewportUtil.UpdateItemViewport(itemName, viewport)
    local item = AssetDealer.GetItem(itemName)
    if not item then warn("Item with name "..itemName.." does not exist") return end

    -- Remove old model and camera if present
    if viewport:FindFirstChild("Model") then
        viewport.Model:Destroy()
    end
    if viewport:FindFirstChild("Camera") then
        viewport.Camera:Destroy()
    end

    viewport.Visible = true
    
    local model = item.Model:Clone()
    setupModelAndCamera(viewport, model)
    return viewport
end

function ViewportUtil.CreateItemViewport(itemName, zIndex: number?)
    local item = AssetDealer.GetItem(itemName)
    if not item then warn("Item with name "..itemName.." does not exist") return nil end
    local viewport = createViewportFrame(zIndex)
    local model = item.Model:Clone()
    setupModelAndCamera(viewport, model)
    return viewport
end

return ViewportUtil