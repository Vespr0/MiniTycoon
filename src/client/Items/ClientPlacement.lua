local ClientPlacement = {}

-- Services --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local _TweenService = game:GetService("TweenService")

-- Folders --
local _Shared = ReplicatedStorage.Shared
local _Packages = ReplicatedStorage.Packages
local Events = ReplicatedStorage.Events
local _Plots = workspace:WaitForChild("Plots")
local Nodes = workspace:WaitForChild("Nodes")

-- Ui Utility --
local Ui = require(script.Parent.Parent.Ui.UiUtility)

-- Modules --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
local AssetsDealer = require(Shared.AssetsDealer)
local PlacementUtility = require(Shared.Plots.PlacementUtility)
local _ItemInfo = require(Shared.Items.ItemInfo)
local _ItemUtility = require(Shared.Items.ItemUtility)
local Signal = require(Packages.signal)
local _SpringModule = require(Shared.Utility.Spring)
local PlacementMenuUi = require(script.Parent.Parent.Ui.Modules.PlacementMenu)

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Constants --
local HIGHLIGHT = Instance.new("Highlight")
local VALID_PLACEMENT_COLOR = Color3.fromRGB(255, 255, 255)
local INVALID_PLACEMENT_COLOR = Color3.fromRGB(255, 51, 112)

-- Variables --
local yRotation = 0
local trove = require(Packages.trove).new()
local isPlacing = false

-- Signals --
ClientPlacement.PlacementStatusUpdated = Signal.new()
ClientPlacement.PlacementFinished = Signal.new()
ClientPlacement.PlacementAborted = Signal.new()
ClientPlacement.PlacementRotated = Signal.new()

-- Functions --

-- Animates the placement of a model with a slight scale effect.
local originalModel = nil -- upvalue for move/cancel logic
local movingFlag = false -- upvalue for move/cancel logic

local function animatePlacement(model: Model)
    if not model or typeof(model) ~= "Instance" then return warn("Error animating placement, model isn't valid.") end
    
    Ui.PlaySound("Place")
    
    -- TODO: Dirty implementation, should be moved to a utility module or something.
    local s = 1
    local function step(factor: number)
        s += factor
        model:ScaleTo(s)
        RunService.RenderStepped:Wait()
    end
    for i = 1,5 do
        step(-0.01)
    end
    for i = 1,8 do
        step(0.01)
    end
    for i = 1,3 do
        step(-0.01)
    end
    return
end

-- Returns the current placement status.
function ClientPlacement.IsPlacing()
    return isPlacing
end

-- Initiates the placement process for an item.
function ClientPlacement.StartPlacing(itemName,model,moving)
    if isPlacing then
        error(`Already placing or moving.`)
        return
    end
    if not itemName and not model then
        error(`either itemName or model must not be nil.`)
        return
    end
    -- Update placement status.
    isPlacing = true
    ClientPlacement.PlacementStatusUpdated:Fire(isPlacing)

    -- Plot.
    local plot = PlacementUtility.GetClientPlot()
    local plotRoot = plot:WaitForChild("Root")

    -- Model.
    originalModel = nil
    movingFlag = moving
    if moving then
        originalModel = model
        originalModel.Parent = ReplicatedStorage.Temp
        model = model:Clone()
    end

    -- Item.
    local item = AssetsDealer.GetItem(itemName)

    --local config = require(item.config)

    -- Model.
    local localID = 0
    if not model then
        model = item.Model:Clone()
    else
        localID = model:GetAttribute("LocalID")
    end
    model.Parent = Nodes
    local modelRoot = model.PrimaryPart
    PlacementUtility.GhostModel(model)

    -- Highlight.
    local highlight = HIGHLIGHT:Clone()
    highlight.Parent = model
    highlight.Enabled = true

    -- Maid (for cleaning up connections).
    Mouse.TargetFilter = Nodes

    -- Variables.
    local lerpTime = 1/20
    local goalCFrame = nil
    local validPlacement = false
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = {workspace.Nodes,model,plot.Drops}

    -- Functions
    -- Switches the highlight color based on placement validity.
    local function switchHighlight(valid)
        local color = valid and VALID_PLACEMENT_COLOR or INVALID_PLACEMENT_COLOR
        highlight.FillColor = color
        highlight.OutlineColor = color
    end
    -- Cleans up the placement model and connections.
    local function clean()
        model:Destroy()
        trove:Clean() -- Clean up all connections managed by this trove
    end
    -- Aborts the current placement process.
    local function abortPlacement()
        isPlacing = false
        ClientPlacement.PlacementStatusUpdated:Fire(isPlacing)
        ClientPlacement.PlacementAborted:Fire()
        PlacementMenuUi.Close()
        clean()
        -- Restore original model if moving and cancelled
        if movingFlag and originalModel then
            local plot = PlacementUtility.GetClientPlot()
            originalModel.Parent = plot.Items
        end
    end
    -- Finalizes the placement of the item.
    local function placeItem()
        isPlacing = false
        ClientPlacement.PlacementFinished:Fire()
        ClientPlacement.PlacementStatusUpdated:Fire(isPlacing)

        clean()
        PlacementMenuUi.Close()

        if moving then
            local result = Events.Move:InvokeServer(localID,goalCFrame.Position,yRotation)
            if not result then
                originalModel.Parent = plot.Items
            end
            animatePlacement(PlacementUtility.WaitForItemFromLocalID(plot.Items,localID))
            return result	
        else
            local localID = Events.Place:InvokeServer(itemName,goalCFrame.Position,yRotation)
            animatePlacement(PlacementUtility.WaitForItemFromLocalID(plot.Items,localID))	
            return localID		
        end		
    end

    local function rotate()
        yRotation += 90
        if yRotation > 360 then
            yRotation = 90
        end
    end

    -- Lerping the model to the target position and rotation.
    local frame = 0
    trove:Connect(RunService.RenderStepped,function(deltaTime)
        frame += 1
        local hit = Mouse.Hit.Position
        local plotHeight = plotRoot.Position.Y+plotRoot.Size.Y/2
        local pos = Vector3.new(hit.X,plotHeight,hit.Z)
        local heightBias = Vector3.yAxis*modelRoot.Size.Y/2

        goalCFrame = CFrame.new(PlacementUtility.SnapPositionToGrid(pos+heightBias,nil,true))*CFrame.Angles(0,math.rad(yRotation),0)
        local lerpedCFrame = modelRoot.CFrame:Lerp(goalCFrame,deltaTime/lerpTime)
        model:PivotTo(lerpedCFrame)

        validPlacement = PlacementUtility.isPlacementValid(plot,model,overlapParams)

        -- Only switch highlight when the model rotation is a multiple of 90, so there aren't any akward highlight flashes 
        -- when rotating a model. This happens because with lerp, the item will be rotated smoothly and that implies a transition 
        -- that has intervals that may touch other models (especially near 45 degrees, because of the rombus like shape).
        -- These frames wouldn't exist without lerping, because clean angles (multiples of 90) fit well in the square grid.
        --local angle = Vector3.new(modelRoot.CFrame - modelRoot.CFrame.Position)
        local angleY = modelRoot.Orientation.Y--math.deg(angle.Y)
        if angleY%90 == 0 then
            switchHighlight(validPlacement) -- Keep highlight switching here based on lerped rotation
        end
    end)

    -- Input Handling via PlacementInput signals
    local PlacementInput = require(script.Parent.Parent.Input.InputModules.PlacementInput)
    trove:Connect(PlacementInput.RotateEvent, function()
        rotate()
    end)
    trove:Connect(PlacementInput.CancelEvent, function()
        abortPlacement()
    end)
    trove:Connect(PlacementInput.PlaceEvent, function()
        if not validPlacement then
            return
        end
        placeItem()
    end)
    -- Open the placement menu UI
    PlacementMenuUi.Open()
end

return ClientPlacement