local ClientLoader = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local LoadingScreen = PlayerGui:WaitForChild("LoadingScreen") :: ScreenGui
local MainFrame = LoadingScreen:WaitForChild("MainFrame")
local ProgressBar = MainFrame:WaitForChild("ContainerBar"):WaitForChild("ProgressBar")
local Context = MainFrame:WaitForChild("Context")

local Events = ReplicatedStorage:WaitForChild("Events")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local FOLDERS = {
	script.Parent.Data;
	script.Parent.Items.Modules;
	script.Parent.FX;
	script.Parent.Ui.Modules;
	script.Parent.Plots;
}

function ClientLoader.SetProgress(percentage)
	percentage = math.clamp(percentage,0,1)
	local tween = TweenService:Create(ProgressBar,TweenInfo.new(.4),{Size = UDim2.fromScale(percentage,1)})
	tween:Play()
end

function ClientLoader.LoadFolder(folder)
	local assets = folder:GetChildren()
	local totalAssets = #assets
	for a = 1,totalAssets do
		ContentProvider:PreloadAsync({assets[a]})
		Context.Text = "Loading "..folder.Name
		ClientLoader.SetProgress(a/totalAssets)
	end
end

function ClientLoader.Start()
	LoadingScreen.Enabled = true
	-- Assets --
	Context.Text = "Loading Assets"
	ClientLoader.SetProgress(0)
	task.wait(1)
	ClientLoader.LoadFolder(Assets.Items.Droppers)
	ClientLoader.LoadFolder(Assets.Tiles)
    -- Modules --
	Context.Text = "Loading Modules"
	ClientLoader.SetProgress(0)

	for i,folder in FOLDERS do
		for _,module in pairs(folder:GetChildren()) do
			if not module:IsA("ModuleScript") then continue end
		    local required = require(module)
			if required.Setup then
				required.Setup()
			end
			task.wait(1/4)
		end
		ClientLoader.SetProgress(i/#FOLDERS)
	end
	ClientLoader.SetProgress(1)
	task.wait(1/2)
	Events.ClientLoaded:FireServer()
	LoadingScreen.Enabled = false
end

return ClientLoader
