local PlacementMenu = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Ui Modules --
local Ui = require(script.Parent.Parent.UiUtility)
local ButtonUtility = require(script.Parent.Util.ButtonUtility)

-- Modules --
local Signal = require(ReplicatedStorage.Packages.signal)

-- Ui Elements 
local Gui = Ui.PlacementMenuGui
local MainFrame = Gui:WaitForChild("MainFrame")
local RotateButton = MainFrame:WaitForChild("Rotate")
local CancelButton = MainFrame:WaitForChild("Cancel")

-- Signals --
PlacementMenu.RotateButtonClicked = Signal.new()
PlacementMenu.CancelButtonClicked = Signal.new()

-- Expose UI elements
PlacementMenu.RotateButton = RotateButton
PlacementMenu.Gui = Gui
PlacementMenu.CancelButton = CancelButton

local function buttonPush(button)
	local icon = button:FindFirstChildOfClass("ImageLabel")
	if not icon then return end

	-- Reset size in case the tween is spammed
	icon.Size = UDim2.fromScale(1, 1)

	local tween = TweenService:Create(icon, ButtonUtility.BOUNCY_BUTTON_TWEEN_INFO, {
		Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(ButtonUtility.BUTTON_OFFSET/2, ButtonUtility.BUTTON_OFFSET/2)
	})

	Ui.PlaySound("Select")
	tween:Play()
end

-- Module Functions
function PlacementMenu.Open()
	Gui.Enabled = true
end

function PlacementMenu.Close()
	Gui.Enabled = false
end

function PlacementMenu.Setup()
	Gui.Enabled = false

	-- Button connections handled by PlacementMenu
	RotateButton.MouseButton1Click:Connect(function()
		PlacementMenu.RotateButtonClicked:Fire()
		buttonPush(RotateButton)
	end)

	CancelButton.MouseButton1Click:Connect(function()
		PlacementMenu.CancelButtonClicked:Fire()
		buttonPush(CancelButton)
	end)
end

return PlacementMenu