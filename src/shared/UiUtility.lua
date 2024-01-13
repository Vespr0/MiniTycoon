local UiUtility = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local PlayerGui = Player.PlayerGui
local ScreenSize = PlayerGui:FindFirstChildOfClass("ScreenGui").AbsoluteSize

function UiUtility.GetDeviceType()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
		and not UserInputService.GamepadEnabled and not GuiService:IsTenFootInterface() then
		return "Mobile"
	end
	return "PC"
end

local DeviceType = Instance.new("StringValue"); DeviceType.Parent = Player
DeviceType.Name = "DeviceType"
DeviceType.Value = UiUtility.GetDeviceType()

function UiUtility.ClearFrame(frame)
	for _,uiElement:GuiBase2d in pairs(frame:GetChildren()) do
		if not uiElement:IsA("UIGridLayout") and not uiElement:IsA("UIListLayout") then
			uiElement:Destroy()
		end
	end
end

function UiUtility.GetUiElementsOverCursor()
	local mousePos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	local GuiObjects = PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
	return GuiObjects
end

function UiUtility.IsAGuiBase2D(instance)
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

function UiUtility.Setup()
	
end

return UiUtility
