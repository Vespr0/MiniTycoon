local PlacementMenu = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
PlacementMenu.CancelButton = CancelButton

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
	end)

	CancelButton.MouseButton1Click:Connect(function()
		PlacementMenu.CancelButtonClicked:Fire()
	end)
end

return PlacementMenu