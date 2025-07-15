local Menu = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local UiModules = script.Parent

local Gui = PlayerGui:WaitForChild("Menu")
local MainFrame = Gui:WaitForChild("MainFrame")

local Ui = require(script.Parent.Parent.UiUtility)

-- Constants
local GUI_NAMES = {
    Storage = "Storage";
    Shop = "Shop";
    ControlPanel = "ControlPanel";
    Index = "Index";
}

local KEY_CODES = {
    [Enum.KeyCode.E] = GUI_NAMES.Storage;
    [Enum.KeyCode.F] = GUI_NAMES.Shop;
    [Enum.KeyCode.G] = GUI_NAMES.ControlPanel;
    [Enum.KeyCode.H] = GUI_NAMES.Index;
}

-- Functions --
local modules = {}
local buttons = {}

-- Helper function to close all other GUIs except the specified one
local function closeAllOtherGuis(currentGuiName)
    for name, buttonData in pairs(buttons) do
        if name ~= currentGuiName then
            local otherGui = PlayerGui:FindFirstChild(name)
            if otherGui and otherGui.Enabled == true then
                -- Close the GUI
                local module = require(modules[name])
                module.Close()
                -- Reset hover state for the button icon
                if buttonData and buttonData.instance and buttonData.instance.Icon and buttonData.origin then
                    Ui.HoverTween(buttonData.instance.Icon, buttonData.origin)
                end
            end
        end
    end
end

-- Function to toggle a specific UI module
local function toggleUi(gui, buttonData)
    local moduleName = gui.Name
    local module = modules[moduleName]
    if not module then
        modules[moduleName] = UiModules[moduleName]
    end
    module = require(modules[moduleName])

    if gui.Enabled then
        module.Close()
        -- Unhover the icon when closing, with nil checks
        if buttonData and buttonData.instance and buttonData.instance.Icon and buttonData.origin then
            Ui.HoverTween(buttonData.instance.Icon, buttonData.origin)
        end
    else
        module.Open()
    end
end

-- Handle button click event
local function handleButtonClick(button)
    local gui = PlayerGui:WaitForChild(button.Name)
    local buttonData = buttons[button.Name]

    if gui and buttonData then
        -- Close all other guis before opening this one
        closeAllOtherGuis(button.Name)

        -- Toggle the clicked GUI
        toggleUi(gui, buttonData)

        -- Set hover state for the clicked icon (if opened)
        if gui.Enabled and buttonData.instance and buttonData.instance.Icon and buttonData.origin then
             Ui.HoverTween(buttonData.instance.Icon, buttonData.origin + Ui.HOVER_INCREMENT)
        end
    end
end

-- Handle keyboard shortcut event
local function handleKeyPress(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    local guiName = KEY_CODES[input.KeyCode]
    if guiName then
        local gui = PlayerGui:FindFirstChild(guiName)
        local buttonData = buttons[guiName]

        if gui and buttonData then
            -- Close all other guis
            closeAllOtherGuis(guiName)

            -- Determine the target position for the icon tween
            local targetPosition = gui.Enabled and buttonData.origin or buttonData.origin + Ui.HOVER_INCREMENT

            -- Toggle the GUI and tween the icon
            -- Ui.PlaySound("Open") TODO: Find a nice sound
            Ui.HoverTween(buttonData.instance.Icon, targetPosition)
            toggleUi(gui, buttonData)
        end
    end
end

function Menu.Setup()
    -- Setup Buttons --
    for _,button in MainFrame:GetChildren() do
        if not button:IsA("ImageButton") then continue end

        -- Propieties --
        local gui = PlayerGui:WaitForChild(button.Name)
        local origin = button.Icon.Position

        -- Store button data
        buttons[button.Name] = {instance=button,origin=origin}

        -- Events --
        button.MouseEnter:Connect(function()
            local goal = origin + Ui.HOVER_INCREMENT
            Ui.HoverTween(button.Icon,goal)
        end)

        button.MouseLeave:Connect(function()
            -- Avoid hovering from resetting the increment to the button's position when it's gui is open.
            if gui.Enabled == true then return end
            local goal = origin
            Ui.HoverTween(button.Icon,goal)
        end)

        button.MouseButton1Click:Connect(function()
            handleButtonClick(button)
        end)
    end

    -- Shortcuts --
    UserInputService.InputBegan:Connect(handleKeyPress)
end

return Menu