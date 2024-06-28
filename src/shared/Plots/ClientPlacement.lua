local ClientPlacement = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Folders --
local _Shared = ReplicatedStorage.Shared
local _Packages = ReplicatedStorage.Packages
local Events = ReplicatedStorage.Events
local _Plots = workspace:WaitForChild("Plots")
local Nodes = workspace:WaitForChild("Nodes")

-- Modules --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
local AssetsDealer = require(Shared.AssetsDealer)
local PlacementUtility = require(Shared.Plots.PlacementUtility)
local ItemInfo = require(Shared.Items.ItemInfo)
local ItemUtility = require(Shared.Items.ItemUtility)
local Signal = require(Packages.signal)

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

-- Signals
ClientPlacement.PlacementStatusUpdated = Signal.new()
ClientPlacement.PlacementFinished = Signal.new()

-- Functions --

function ClientPlacement.IsPlacing()
    return isPlacing
end

function ClientPlacement.StartPlacing(itemName,model,moving)
    if isPlacing then
        warn("Client is already placing or moving.")
        return
    end
    -- Update placement status.
    isPlacing = true
    ClientPlacement.PlacementStatusUpdated:Fire(isPlacing)

    -- Plot.
    local plot = PlacementUtility.GetClientPlot()
    local plotRoot = plot:WaitForChild("Root")

    -- Model.
    local originalModel
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

    -- Maid.
    Mouse.TargetFilter = Nodes

    -- Variables.
    local lerpTime = 1/20
    local goalCFrame = nil
    local validPlacement = false
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = {workspace.Nodes,model,plot.Drops}

    -- Functions
    local function switchHighlight(valid)
        local color = valid and VALID_PLACEMENT_COLOR or INVALID_PLACEMENT_COLOR
        highlight.FillColor = color
        highlight.OutlineColor = color
    end
    local function clean()
        model:Destroy()
        trove:Clean()
    end
    local function abortPlacement()
        isPlacing = false
        ClientPlacement.PlacementStatusUpdated:Fire(isPlacing)
        clean()
    end
    local function placeItem()
        isPlacing = false
        ClientPlacement.PlacementFinished:Fire()
        ClientPlacement.PlacementStatusUpdated:Fire(isPlacing)

        clean()
        if moving then
            local result = Events.Move:InvokeServer(localID,goalCFrame.Position,yRotation)
            if not result then
                originalModel.Parent = plot.Items
            end
            return result
        else
            return Events.Place:InvokeServer(itemName,goalCFrame.Position,yRotation)
        end
    end

    -- Lerping
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
            switchHighlight(validPlacement)
        end
    end)

    -- Input --
    trove:Connect(UserInputService.InputBegan,function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not validPlacement then
                return
            end
            placeItem()
        end
        if input.KeyCode == Enum.KeyCode.R then
            yRotation += 90
            if yRotation > 360 then
                yRotation = 90
            end
        end
        if input.KeyCode == Enum.KeyCode.Q then
            abortPlacement()
        end
    end)
end

return ClientPlacement