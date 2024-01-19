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

function ClientPlacement.StartPlacing(name,model,moving)
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
    local item
    if not model then
        item = AssetsDealer.GetItem(ItemInfo[name].Directory)
    else
        item = ItemUtility.GetItemFromID(model:GetAttribute("ID"))
    end
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
            return Events.Place:InvokeServer(ItemInfo[name].ID,goalCFrame.Position,yRotation)
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

        if frame%2 == 0 then
            validPlacement = PlacementUtility.isPlacementValid(plot,model,overlapParams)
            switchHighlight(validPlacement)
        end
    end)

    -- Input --
    trove:Connect(UserInputService.InputBegan,function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if validPlacement and input.UserInputType == Enum.UserInputType.MouseButton1 then
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