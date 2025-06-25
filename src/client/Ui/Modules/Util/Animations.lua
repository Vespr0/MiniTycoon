local Animations = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared

local AssetsDealer = require(Shared.AssetsDealer)

-- Modules
local Ui = require(script.Parent.Parent.Parent.UiUtility)
local Tween = require(script.Parent.Tween)

local Functions = {
	Button = {
		ClassNames = {
			"TextButton","ImageButton"
		},
		Function = function(button)
			button.MouseEnter:Connect(function()
				Tween.HoverButton(button)
			end)
			button.MouseLeave:Connect(function()
				Tween.ReverseHoverButton(button)
			end)
		end,
	}
}

function Animations.Setup()
	
	-- Run though all ui elements
	for _,d in Ui.PlayerGui:GetDescendants() do
		for _,func in Functions do
			if table.find(func.ClassNames,d.ClassName) then
				func.Function(d)
			end
		end
	end
end

return Animations