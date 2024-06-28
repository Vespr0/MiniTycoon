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

-- Functions --
local modules = {}
local function toggleUi(gui)
    -- As we use require modules put them into a folder, so modules arent required again.
    local module = modules[gui.Name]
    if not module then
        modules[gui.Name] = UiModules[gui.Name]
    end
    module = require(modules[gui.Name])
    if gui.Enabled then
        module.Close()
    else
        module.Open()
    end
end

function Menu.Setup()
    -- Setup Buttons --
    local buttons = {}
    for _,button in MainFrame:GetChildren() do
        if not button:IsA("ImageButton") then continue end
        -- Propieties --
        local gui = PlayerGui:WaitForChild(button.Name)
        local origin = button.Icon.Position
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
            if gui then
                toggleUi(gui)
            end
        end)
        buttons[button.Name] = {instance=button,origin=origin}
    end
    -- Shortcuts --
    local keyCodes = {
        E = "Storage";
        F = "Shop";
    }
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        for key,value in keyCodes do
            if input.KeyCode == Enum.KeyCode[key] then
                local gui = PlayerGui:FindFirstChild(value)
                if gui then
                    local origin = buttons[value].origin
                    local goal = gui.Enabled and origin or origin+Ui.HOVER_INCREMENT
                    Ui.HoverTween(buttons[value].instance.Icon,goal)
                    toggleUi(gui)

                    -- Close all other guis
                    for _,otherValue in pairs(keyCodes) do
                        if otherValue == value then continue end
                        local otherGui = PlayerGui:FindFirstChild(otherValue)
                        if otherGui and otherGui.Enabled == true then
                            Ui.HoverTween(buttons[otherValue].instance.Icon,origin)
                            toggleUi(otherGui)
                        end
                    end
                end
            end
        end
    end)
end

return Menu