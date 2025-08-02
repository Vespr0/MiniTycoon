local ClientItemsReplication = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Events = ReplicatedStorage.Events
local Packages = ReplicatedStorage.Packages

-- LocalPlayer --
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Mouse = Player:GetMouse()
local Camera = workspace.Camera

-- Modules --
local PlacementUtility = require(Shared.Plots.PlacementUtility)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.Placement.ClientPlacement)
local ItemUtility = require(Shared.Items.ItemUtility)
local PlotUtility = require(Shared.Plots.PlotUtility)

-- Classes --
local ClientDropper = require(script.Parent.Parent.Droppers.ClientDropper)
local Signal = require(Packages.signal)

-- Variables --
repeat
	task.wait(0.2)
until Player:GetAttribute("Plot") and PlacementUtility.GetClientPlot()
local Plot = PlacementUtility.GetClientPlot()

ReplicationFunctions = {}

ReplicationFunctions.Dropper = function(args)
	local model = args.model

	-- If we have a localID instead of a model, get the model
	if not model and args.localID then
		model = PlacementUtility.WaitForItemFromLocalID(Plot.Items, args.localID, 5)

		if not model then
			error(`Tried to get replicated item from localID ({args.localID}) but was not found.`)
			return
		end
	end

	-- Instanciate class
	local dropper = ClientDropper.new({
		model = model,
		dropPropieties = args.config.DropPropieties,
		config = args.config,
		plot = Plot,
	})

	repeat
		task.wait(1)
	until not dropper:exists()
end

function ClientItemsReplication.Replicate(itemType, args)
	if not ReplicationFunctions[itemType] then
		-- warn("No replication function for type: " .. itemType)
		return
	end
	ReplicationFunctions[itemType](args)
end

function ClientItemsReplication.ReplicateWithModel(itemType, model, config)
	if not ReplicationFunctions[itemType] then
		-- warn("No replication function for type: " .. itemType)
		return
	end
	ReplicationFunctions[itemType]({
		model = model,
		config = config,
	})
end

function ClientItemsReplication.Setup()
	-- Replicate existing items directly with their models
	for _, item in pairs(Plot.Items:GetChildren()) do
		local itemType = item:GetAttribute("ItemType")
		local config = ItemUtility.GetItemConfig(item.Name)

		if itemType and config then
			ClientItemsReplication.ReplicateWithModel(itemType, item, config)
		end
	end

	Events.ItemReplication.OnClientEvent:Connect(function(itemType, args)
		ClientItemsReplication.Replicate(itemType, args)
	end)
end

return ClientItemsReplication
