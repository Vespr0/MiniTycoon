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
local ClientPlacement = require(script.Parent.Parent.Parent.Items.ClientPlacement)
local ItemUtility = require(Shared.Items.ItemUtility)
local PlotUtility = require(Shared.Plots.PlotUtility)

-- Classes --
local ClientDropper = require(script.Parent.Parent.Droppers.ClientDropper)
local Signal = require(Packages.signal)

-- Variables --
repeat task.wait(.2) until Player:GetAttribute("Plot") and PlacementUtility.GetClientPlot()
local Plot = PlacementUtility.GetClientPlot()

ReplicationFunctions = {} 

ReplicationFunctions.Dropper = function(args)
    local localID = args.localID

    local item
    local time = 0
    -- Wait for item to be replicated
    while not item and time < 5 do
        item = PlacementUtility.GetItemFromLocalID(Plot.Items,localID)
        time += task.wait(0.1)
    end
    
    if not item then
        error("Trying to get replicated item from localID but got nil.")
        return
    end

    -- Instanciate class
    local dropper = ClientDropper.new({
        model = item,
        dropPropieties = args.config.DropPropieties,
        config = args.config,
        plot = Plot
    })

    repeat task.wait(1) until not dropper:exists()
end

function ClientItemsReplication.Replicate(itemType,args)
    if not ReplicationFunctions[itemType] then
        -- warn("No replication function for type: " .. itemType)
        return 
    end
    ReplicationFunctions[itemType](args)
end

-- TODO: items that existed before the setup run are replicated with the for loop below.
-- Said loop sends localID gotten from the item model to identify it, the replicate function
-- then converts it back to a model. This is silly.

function ClientItemsReplication.Setup()
    -- Replicate existing items
    for _,item in pairs(Plot.Items:GetChildren()) do
        local localID = item:GetAttribute("LocalID")
        local itemType = item:GetAttribute("ItemType")
        local config = ItemUtility.GetItemConfig(item.Name)
            
        if localID then
            ClientItemsReplication.Replicate(itemType,{
                localID = localID,
                config = config
            })
        end
    end

    Events.ItemReplication.OnClientEvent:Connect(function(itemType,args)
        ClientItemsReplication.Replicate(itemType,args)
    end)
end

return ClientItemsReplication