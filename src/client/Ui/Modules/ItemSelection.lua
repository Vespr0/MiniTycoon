local ItemSelection = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Nodes = workspace:WaitForChild("Nodes")
local Events = ReplicatedStorage.Events
local _Plots = workspace:WaitForChild("Plots")

-- Modules --
-- TODO: this module was made without using ui utility, only adding it now, should clean the code up.
local Ui = require(script.Parent.Parent.UiUtility)
local PlacementUtility = require(Shared.Plots.PlacementUtility)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.ClientPlacement)
local ItemUtility = require(Shared.Items.ItemUtility)
local ItemSelectionInput = require(script.Parent.Parent.Parent.Input.InputModules.ItemSelectionInput)

-- LocalPlayer --
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Mouse = Player:GetMouse()
local Camera = workspace.Camera

-- Gui elements --
local Gui = PlayerGui:WaitForChild("ItemSelection")
local MainFrame = Gui:WaitForChild("MainFrame")
local Container = MainFrame:WaitForChild("Container")
local Background = MainFrame:WaitForChild("Background")

-- Variables --
local CurrentllySelectedItem = nil
local CurrentllyHoveredItem = nil
repeat task.wait(.2) until Player:GetAttribute("Plot") and PlacementUtility.GetClientPlot()
local Plot = PlacementUtility.GetClientPlot()

-- Constants --
local HOVER_HIGHLIGHT = Instance.new("Highlight");HOVER_HIGHLIGHT.Parent = Nodes.Visuals
local SELECTION_HIGHLIGHT = Instance.new("Highlight");SELECTION_HIGHLIGHT.Parent = Nodes.Visuals

HOVER_HIGHLIGHT.FillTransparency = 1
HOVER_HIGHLIGHT.OutlineTransparency = 0

SELECTION_HIGHLIGHT.FillColor = Color3.fromRGB(255, 255, 255)
SELECTION_HIGHLIGHT.FillTransparency = 0.9
SELECTION_HIGHLIGHT.OutlineTransparency = 0

local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
RAYCAST_PARAMS.FilterDescendantsInstances = {Plot}

-- Functions --
local function fadeUpAnimation()
    Container.Position = UDim2.fromScale(.5,.5)
    Background.Position = UDim2.fromScale(.5,.5)
    
    local tweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Sine)
    local tween1 = TweenService:Create(Container,tweenInfo,{Position = UDim2.fromScale(.5,.4)})
    local tween2 = TweenService:Create(Background,tweenInfo,{Position = UDim2.fromScale(.5,.4)})
    
    tween1:Play()
    tween2:Play()
end

local function moveGui(item)
    local vector,onScreen = Camera:WorldToScreenPoint(item.PrimaryPart.Position+Vector3.yAxis*2)
    if not onScreen then MainFrame.Visible = false return end
    
    MainFrame.Visible = true
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

local function toggleSelectionHighlight(bool)
    SELECTION_HIGHLIGHT.Enabled = bool
end

local function updateSelectionHighlight(item)
    SELECTION_HIGHLIGHT.Adornee = item
end

local function updateHoverHighlight(item)
    HOVER_HIGHLIGHT.Adornee = item
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
    Container.ItemNameLabel.Text = config.DisplayName
    updateSelectionHighlight(item)
    toggleSelectionHighlight(true) 
    fadeUpAnimation()
    CurrentllySelectedItem = item
end

local function unSelect()
    Gui.Enabled = false
    toggleSelectionHighlight(false)
    CurrentllySelectedItem = nil
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

local function move()
    if not CurrentllySelectedItem then return end
    local localID = CurrentllySelectedItem:GetAttribute("LocalID")
    local item = PlacementUtility.GetItemFromLocalID(Plot.Items,localID)
    if not item then
        error(`Couldn't find item with localID "{localID}" in folder Items in Plot.`)
    end
    ClientPlacement.StartPlacing(item.Name,item,true)
    unSelect()
end

local function deposit()
    if not CurrentllySelectedItem then return end
    Events.Deposit:InvokeServer(CurrentllySelectedItem:GetAttribute("LocalID"))
    unSelect()
end

function ItemSelection.Setup()
    RunService.RenderStepped:Connect(update)
    MainFrame.Visible = false

    -- Selection
    ItemSelectionInput.SelectEvent:Connect(function()
        if CurrentllyHoveredItem then
            if not ClientPlacement.IsPlacing() then
                select(CurrentllyHoveredItem)
            end
        else
            unSelect()
        end
    end)
    -- Move
    ItemSelectionInput.MoveEvent:Connect(function()
        move()
        Ui.PlaySound("Collect")
    end)
    -- Deposit
    ItemSelectionInput.StoreEvent:Connect(function()
        deposit()
        Ui.PlaySound("Collect")
    end)
end

return ItemSelection