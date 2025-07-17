local ClientLoader = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")


local LoadingScreen = require(script.Parent.Ui.Modules.LoadingScreen)

local Events = ReplicatedStorage:WaitForChild("Events")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local FOLDERS = {
	script.Parent.Data;
	script.Parent.Items.Modules;
	script.Parent.FX;
	script.Parent.Ui.Modules;
	script.Parent.Plots;
	script.Parent.Input
}

function ClientLoader.SetProgress(percentage)
	LoadingScreen.SetProgress(percentage)
end

function ClientLoader.LoadFolder(folder)
	local assets = folder:GetChildren()
	local totalAssets = #assets
	for a = 1, totalAssets do
		ContentProvider:PreloadAsync({assets[a]})
		LoadingScreen.SetContext("Loading " .. folder.Name)
		ClientLoader.SetProgress(a / totalAssets)
	end
end

function ClientLoader.Start()
	LoadingScreen.Open()
	-- Assets --
	LoadingScreen.SetContext("Loading Assets")
	ClientLoader.SetProgress(0)
	task.wait(.1)
	ClientLoader.LoadFolder(Assets.Items.Droppers)
	ClientLoader.LoadFolder(Assets.Tiles)
	-- Modules --
	LoadingScreen.SetContext("Loading Modules")
	ClientLoader.SetProgress(0)

	for i, folder in FOLDERS do
		for _, module in pairs(folder:GetChildren()) do
			if not module:IsA("ModuleScript") then continue end
			local required = require(module)
			if required.Setup then
				required.Setup()
			end
			task.wait(.1)
		end
		ClientLoader.SetProgress(i / #FOLDERS)
	end
	ClientLoader.SetProgress(1)
	task.wait(.1)
	Events.ClientLoaded:FireServer()
	LoadingScreen.Close()
end

return ClientLoader
