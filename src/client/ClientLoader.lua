local ClientLoader = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Signal = require(ReplicatedStorage.Packages.signal)
local LoadingUtility = require(ReplicatedStorage.Shared.Utility.LoadingUtility)
local LoadingScreen = require(script.Parent.Ui.Modules.LoadingScreen)

local Events = ReplicatedStorage:WaitForChild("Events")

ClientLoader.ClientLoadedEvent = Signal.new()
ClientLoader.ClientLoaded = false

local FOLDERS = {
	script.Parent.Data;
	script.Parent.Items.Modules;
	script.Parent.FX;
	script.Parent.Ui.Modules;
	script.Parent.Plots;
	script.Parent.Input;
	script.Parent.Players
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
	-- TODO: May be uneccessary and may just lag mobile
	-- ClientLoader.LoadFolder(Assets.Items.Droppers)
	-- Modules --
	LoadingScreen.SetContext("Loading Modules")
	ClientLoader.SetProgress(0)

	-- Collect all modules with Setup functions
	local modules = LoadingUtility.CollectModules(FOLDERS)
	
	-- Resolve dependencies and sort modules
	local sortedModules = LoadingUtility.ResolveDependencies(modules)
	
	-- Load modules in dependency order
	LoadingUtility.LoadModules(
		sortedModules,
		function(progress) ClientLoader.SetProgress(progress) end,
		function(context) LoadingScreen.SetContext(context) end
	)

	ClientLoader.SetProgress(1)
	LoadingScreen.SetContext("Loading Game")
	task.wait(3)
	Events.ClientLoaded:InvokeServer()
	ClientLoader.ClientLoaded = true
	ClientLoader.ClientLoadedEvent:Fire()
	LoadingScreen.Close()
end

return ClientLoader
