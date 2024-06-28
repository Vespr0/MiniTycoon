local ItemSelection = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Nodes = workspace:WaitForChild("Nodes")
local Events = ReplicatedStorage.Events
local _Plots = workspace:WaitForChild("Plots")

-- LocalPlayer --
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Mouse = Player:GetMouse()
local Camera = workspace.Camera

-- Gui elements --
local Gui = PlayerGui:WaitForChild("ItemSelection")
local MainFrame = Gui:WaitForChild("MainFrame")
local SubFrame = MainFrame:WaitForChild("SubFrame")

-- Modules --
local PlacementUtility = require(Shared.Plots.PlacementUtility)
local ClientPlacement = require(Shared.Plots.ClientPlacement)
local ItemUtility = require(Shared.Items.ItemUtility)

-- Variables --
local CurrentllySelectedItem = nil
local CurrentllyHoveredItem = nil
repeat task.wait(.2) until Player:GetAttribute("Plot") and PlacementUtility.GetClientPlot()
local Plot = PlacementUtility.GetClientPlot()

-- Constants --
local HOVER_HIGHLIGHT = Instance.new("Highlight");HOVER_HIGHLIGHT.Parent = Nodes.Visuals
local SELECTION_HIGHLIGHT = Instance.new("Highlight");SELECTION_HIGHLIGHT.Parent = Nodes.Visuals
HOVER_HIGHLIGHT.FillTransparency = 0.7
HOVER_HIGHLIGHT.OutlineTransparency = 1
SELECTION_HIGHLIGHT.FillTransparency = 0.7
SELECTION_HIGHLIGHT.OutlineTransparency = 1
local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
RAYCAST_PARAMS.FilterDescendantsInstances = {Plot}

-- Functions --
local function moveGui(item)
    local vector,onScreen = Camera:WorldToScreenPoint(item.PrimaryPart.Position)
    if not onScreen then return end
	MainFrame.Position = UDim2.fromOffset(vector.X,vector.Y)
end

local function getItemFromPart(part)
    for _,item in pairs(Plot.Items:GetChildren()) do
        if part:IsDescendantOf(item) then
            return item
        end
    end
    return nil
end

local function updateSelectionHighlight(item)
    HOVER_HIGHLIGHT.Adornee = item
end

local function updateHoverHighlight(item)
    HOVER_HIGHLIGHT.Adornee = item
end

local function toggleSelectionHighlight(bool)
    SELECTION_HIGHLIGHT.Enabled = bool
end

local function toggleHoverHighlight(bool)
    HOVER_HIGHLIGHT.Enabled = bool
end

local function hover(item)
    CurrentllyHoveredItem = item
    if CurrentllySelectedItem then return end
    updateHoverHighlight(CurrentllyHoveredItem)
    toggleHoverHighlight(true)
end

local function unHover()
    CurrentllyHoveredItem = nil
    if CurrentllySelectedItem then return end
    toggleHoverHighlight(false)
end

local function select(item)
    Gui.Enabled = true
    local config = ItemUtility.GetItemConfig(item.Name)
    SubFrame.ItemNameLabel.Text = config.DisplayName
    updateSelectionHighlight(item)
    CurrentllySelectedItem = item
end

local function unSelect()
    Gui.Enabled = false
    CurrentllySelectedItem = nil
    toggleSelectionHighlight(false)
end

local function update()
    if CurrentllySelectedItem then
        moveGui(CurrentllySelectedItem)
    end

	local raycast = workspace:Raycast(Camera.CFrame.Position,Mouse.UnitRay.Direction*100,RAYCAST_PARAMS)
    if raycast then
        local part = raycast.Instance
        if part then
            local item = getItemFromPart(part)
            if item then
                hover(item)
                return
            end
        end
    end
    unHover()
end

local function deposit(localID)
    Events.Deposit:InvokeServer(localID)
end

function ItemSelection.Setup()
    RunService.RenderStepped:Connect(update)

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        -- Selecting
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if CurrentllyHoveredItem then
                if not ClientPlacement.IsPlacing() then
                    select(CurrentllyHoveredItem)
                end
            else
                unSelect()
            end
        end

        -- Moving
        if input.KeyCode == Enum.KeyCode.V then
            if CurrentllySelectedItem then
                local item = PlacementUtility.GetItemFromLocalID(Plot.Items,CurrentllySelectedItem:GetAttribute("LocalID"))
                ClientPlacement.StartPlacing(nil,item,true)
            end
        end

        -- Storing
        if input.KeyCode == Enum.KeyCode.B then
            if CurrentllySelectedItem then
                deposit(CurrentllySelectedItem:GetAttribute("LocalID"))
                unSelect()
            end
        end
    end)
end

return ItemSelection