local ServerLoader = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.signal)
local LoadingUtility = require(ReplicatedStorage.Shared.Utility.LoadingUtility)

ServerLoader.ServerLoadedEvent = Signal.new()
ServerLoader.ServerLoaded = false

local FOLDERS = {
	script.Parent.Data,
	script.Parent.Items,
	script.Parent.Services,
	script.Parent.Analytics,
	script.Parent.Plots,
	script.Parent.Unboxing,
}

function ServerLoader.Start()
	print("Starting server module loading...")

	-- Collect all modules with Setup functions
	local modules = LoadingUtility.CollectModules(FOLDERS)

	-- Resolve dependencies and sort modules
	local sortedModules = LoadingUtility.ResolveDependencies(modules)

	-- Load modules in dependency order
	LoadingUtility.LoadModules(sortedModules, function(progress)
		print("Server loading progress: " .. math.floor(progress * 100) .. "%")
	end, function(context)
		print(context)
	end)

	print("Server modules loaded successfully!")
	ServerLoader.ServerLoaded = true
	ServerLoader.ServerLoadedEvent:Fire()
end

return ServerLoader
