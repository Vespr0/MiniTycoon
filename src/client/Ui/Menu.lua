local Menu = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local Ui = script.Parent

local Gui = PlayerGui:WaitForChild("Menu")
local MainFrame = Gui:WaitForChild("MainFrame")

local TWEEN_INFO = TweenInfo.new(.15,Enum.EasingStyle.Sine)
local HOVER_INCREMENT = UDim2.fromOffset(5,0)

-- Functions --
local function tweenHover(button,goal)
    local tween = TweenService:Create(button,TWEEN_INFO,{Position = goal})
    tween:Play()
end

local modules = {}
local function toggleUi(gui)
    -- As we use require modules put them into a folder, so modules arent required again.
    local module = modules[gui.Name]
    if not module then
        modules[gui.Name] = Ui[gui.Name]
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
            local goal = origin + HOVER_INCREMENT
            tweenHover(button.Icon,goal)
        end)
        button.MouseLeave:Connect(function()
            -- Avoid hovering from resetting the increment to the button's position when it's gui is open.
            if gui.Enabled == true then return end
            local goal = origin
            tweenHover(button.Icon,goal)
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
                    local goal = gui.Enabled and origin or origin+HOVER_INCREMENT
                    tweenHover(buttons[value].instance.Icon,goal)
                    toggleUi(gui)
                end
            end
        end
    end)
end

return Menu