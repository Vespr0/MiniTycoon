local Ui = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Variables
local PlayerGui = Player.PlayerGui
local ScreenSize = PlayerGui:FindFirstChildOfClass("ScreenGui").AbsoluteSize

-- Ui Elements
Ui.Player = Players.LocalPlayer
Ui.PlayerGui = PlayerGui
Ui.ControlPanelGui = PlayerGui:WaitForChild("ControlPanel")
Ui.StorageGui = PlayerGui:WaitForChild("Storage")
Ui.ShopGui = PlayerGui:WaitForChild("Shop")
Ui.UnboxingGui = PlayerGui:WaitForChild("Unboxing")
Ui.IndexGui = PlayerGui:WaitForChild("Index")
Ui.PlacementMenuGui = PlayerGui:WaitForChild("PlacementMenu")

-- Constants
Ui.BUTTON_UNSELECTED_COLOR = Color3.fromRGB(27, 27, 27)
Ui.BUTTON_SELECTED_COLOR = Color3.fromRGB(255, 255, 255)
Ui.HOVER_INCREMENT = UDim2.fromOffset(5,0)
Ui.MENU_TWEEN_INFO = TweenInfo.new(.15,Enum.EasingStyle.Sine)

-- Modules 
local SoundManager = require(ReplicatedStorage.Shared.Sound.SoundManager)

-- Functions
function Ui.GetDeviceType()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
		and not UserInputService.GamepadEnabled and not GuiService:IsTenFootInterface() then
		return "MOBILE"
	end
	return "PC"
end
local DeviceType = Instance.new("StringValue"); DeviceType.Parent = Player
DeviceType.Name = "DeviceType"
DeviceType.Value = Ui.GetDeviceType()

local CLEAR_FRAME_BLACKLIST = {
    "UIGridLayout",
    "UIListLayout"
}
function Ui.ClearFrame(frame)
	for _,uiElement:GuiBase2d in pairs(frame:GetChildren()) do
		if table.find(CLEAR_FRAME_BLACKLIST, uiElement.ClassName) then
			continue
		end
		uiElement:Destroy()
	end
end

function Ui.IsButton(instance)
    return instance:IsA("ImageButton") or instance:IsA("TextButton")
end

function Ui.GetUiElementsOverCursor()
	local mousePos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	local GuiObjects = PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
	return GuiObjects
end

function Ui.IsAGuiBase2D(instance)
    local classes = {
        "Frame";
        "ImageButton";
        "TextLabel";
        "ScrollingFrame";
        "TextButton";
    }
    for _,className in pairs(classes) do
        if instance:IsA(className) then
            return true
        end
    end
    return false
end

function Ui.PlaySound(directory)
	SoundManager.PlaySound("Ui/"..directory,nil,1)
end

function Ui.HoverTween(button,goal)
    local tween = TweenService:Create(button,Ui.MENU_TWEEN_INFO,{Position = goal})
    tween:Play()
end

return Ui