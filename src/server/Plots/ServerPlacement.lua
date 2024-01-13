local ServerPlacement = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Events = ReplicatedStorage.Events
local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server

-- Modules --
local PlacementUtility = require(Shared.Plots.PlacementUtility)
local AssetsDealer = require(Shared.AssetsDealer)
local ItemUtility = require(Shared.Items.ItemUtility)
local PlotUtility = require(Shared.Plots.PlotUtility)
-- Classes --
local ServerDropper = require(Server.Items.Droppers.ServerDropper)
local PlayerDataManager = require(Server.Data.PlayerDataManager)
local PlayerDataAccess = require(Server.Data.PlayerDataAccess)

local errors = {
    -- Arguments.
    InvalidArgumentType = "Invalid argument from client: ``&a`` argument is invalid.";
    -- Placement Validity.
    InvalidPositionAndRotation = "Invalid position and rotation from client.";
    -- Item Info.
    ItemNameDoesntExist = "Invalid item name from client: ``&a`` isn't a valid entry in the items archive.";
    -- Storage.
    PlayerDoesntHaveStorageItem = "Player requested placement but does not own the item.";
    -- Placed Items.
    PlayerDoesntHavePlacedItemToMove = "Invalid placed item localID: ``&a`` from player to move, no physical placed item.";
    PlayerDoesntHavePlacedItemInDatastoreToMove = "Invalid placed item localID: ``&a`` from player to move, placed item isn't in datastore.";
    PlayerDoesntHavePlacedItemToStore = "Invalid placed item localID: ``&a`` from player to store, no physical placed item.";
    PlayerDoesntHavePlacedItemInDatastoreToStore = "Invalid placed item localID: ``&a`` from player to store, placed item isn't in datastore.";
}

local function findAvaiableItemLocalID(folder)
    local id = 0
    while true do
        id += 1
        local avaiable = true
        for _,item in pairs(folder:GetChildren()) do
            if item:GetAttribute("LocalID") == id then
                avaiable = false
                break
            end
        end
        if not avaiable then continue end
        return id
    end
end

function ServerPlacement.DisableQueries(model)
    for _,d in pairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            if d ~= model.PrimaryPart then
                d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
            else
                d.CanCollide = true
            end
            d.Anchored = true
        end
    end
end

function ServerPlacement.PlaceItem(player,position,itemID,yRotation,localID,filteredModel)
    local name,entry = ItemUtility.GetItemFromID(itemID)

    if entry then
        -- Get item info.
        local plot = PlotUtility.GetPlotFromPlayer(player)
        local item = AssetsDealer.GetItem(entry.Directory)
        local stats = require(item.Stats)
        local type = stats.Type

        -- Place the model.
        local model = item.Model:Clone()
        model.Parent = plot.Items
        model.Name = name
        local yAngle = math.rad(math.clamp(yRotation,0,360))
        model:PivotTo(CFrame.new(position)*CFrame.Angles(0,yAngle,0))

        -- Variables
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {workspace.Nodes,plot.Drops,model,filteredModel}

        -- Validate placement.
        local isPlacementValid = PlacementUtility.isPlacementValid(plot,model,overlapParams)
        if isPlacementValid then
            -- IDs.
            if not localID then
                localID = findAvaiableItemLocalID(plot.Items)
            end
            model:SetAttribute("LocalID",localID)
            model:SetAttribute("ID",itemID)
            ServerPlacement.DisableQueries(model)

            -- Instanciate classes.
            local placementFunctions = {
                Dropper = function()
                    ServerDropper.new({
                        plot = plot;
                        owner = player;
                        model = model;
                        dropDelay = stats.DropDelay;
                        dropPropieties = stats.DropPropieties;
                    })
                end;
                Belt = function()
                    model.Root:SetAttribute("Speed",stats.BeltSpeed)
                end;
                Forge = function()
                    model.Root:SetAttribute("SellMultiplier",stats.SellMultiplier)
                end;
                Upgrader = function()

                end;
            }
            task.defer(placementFunctions[type])
            return true,localID
        else
            model:Destroy()
            local str = " position:"..tostring(position).." yRotation:"..tostring(yRotation).." itemID:"..tostring(item)
            return false,string.gsub(errors.InvalidPositionAndRotation,"&a",str)
        end
    else
        return false,string.gsub(errors.ItemNameDoesntExist,"&a",itemID)
    end
end

function ServerPlacement.Setup()
    Events.Place.OnServerInvoke = function(player,itemID,position,yRotation)
        local actionTag = " > Events.Place"
        local playerTag = " #"..player.UserId

        if typeof(position) ~= "Vector3" then warn(string.gsub(errors.InvalidArgumentType,"&a","position")..playerTag..actionTag); return false end
        if typeof(yRotation) ~= "number" then warn(string.gsub(errors.InvalidArgumentType,"&a","yRotation")..playerTag..actionTag); return false end
        if typeof(itemID) ~= "number" then warn(string.gsub(errors.InvalidArgumentType,"&a","itemID")..playerTag..actionTag); return false end

        local storageItem = PlayerDataAccess.GetStorageItem(player,itemID)
        if not storageItem then warn(errors.PlayerDoesntHaveStorageItem..playerTag..actionTag); return false end

        local success,arg1 = ServerPlacement.PlaceItem(player,position,itemID,yRotation)

        if not success then warn("Error from player placement request : ``"..arg1.."``"..playerTag..actionTag); return false end

        PlayerDataAccess.RegisterPlacedItem(player,arg1,position,itemID,yRotation)
        PlayerDataAccess.ConsumeStorageItems(player,itemID,1)
        return true
    end
    Events.Move.OnServerInvoke = function(player,localID,position,yRotation)
        local actionTag = " > Events.Move"
        local playerTag = " #"..player.UserId

        if typeof(position) ~= "Vector3" then warn(string.gsub(errors.InvalidArgumentType,"&a","position")..playerTag..actionTag); return false end
        if typeof(yRotation) ~= "number" then warn(string.gsub(errors.InvalidArgumentType,"&a","yRotation")..playerTag..actionTag); return false end
        if typeof(localID) ~= "number" then warn(string.gsub(errors.InvalidArgumentType,"&a","itemID")..playerTag..actionTag); return false end

        local plot = PlotUtility.GetPlotFromPlayer(player)
        local placedModel = PlacementUtility.GetItemFromLocalID(plot.Items,localID)
        local placedItem = PlayerDataAccess.GetPlacedItem(player,localID)
        if not placedModel then warn(errors.PlayerDoesntHavePlacedItemToMove..playerTag..actionTag); return false end
        if not placedItem then warn(errors.PlayerDoesntHavePlacedItemInDatastoreToMove..playerTag..actionTag); return false end
        local placedItemID = placedItem[4]

        -- Move.
        local success,arg1 = ServerPlacement.PlaceItem(player,position,placedItemID,yRotation,localID,placedModel)
        if not success then warn("Error from player placement request : ``"..arg1.."``"..playerTag..actionTag); return false end

        PlayerDataAccess.RegisterPlacedItem(player,localID,position,placedItemID,yRotation)
        placedModel:Destroy()
        --PlayerDataAccess.ConsumeStorageItems(player,placedItemID,1)
        return true
    end
    Events.Deposit.OnServerInvoke = function(player,localID)
        local actionTag = " > Events.Deposit"
        local playerTag = " #"..player.UserId

        if typeof(localID) ~= "number" then warn(string.gsub(errors.InvalidArgumentType,"&a","itemID")..playerTag..actionTag); return false end

        local plot = PlotUtility.GetPlotFromPlayer(player)
        local placedModel = PlacementUtility.GetItemFromLocalID(plot.Items,localID)
        local placedItem = PlayerDataAccess.GetPlacedItem(player,localID)
        if not placedModel then warn(errors.PlayerDoesntHavePlacedItemToStore..playerTag..actionTag); return false end
        if not placedItem then warn(errors.PlayerDoesntHavePlacedItemToStore..playerTag..actionTag); return false end
        local placedItemID = placedItem[4]

        placedModel:Destroy()
        PlayerDataAccess.RemovePlacedItem(player,localID)
        PlayerDataAccess.GiveStorageItems(player,placedItemID,1)
        return true
    end
end

return ServerPlacement