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
            if d ~= model.PrimaryPart and d.Parent.Name ~= "Hitbox" then
                --d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
            else
                --d.CanCollide = true
            end
            d.Anchored = true
        end
    end
end

function ServerPlacement.PlaceItem(player,position,itemID,yRotation,localID,filteredModel,ignoreValidation)
    local name,entry = ItemUtility.GetItemFromID(itemID)

    if entry then
        -- Get item info.
        local plot = PlotUtility.GetPlotFromPlayer(player)
        local item = AssetsDealer.GetItem(entry.Directory)
        local config = require(item.config)
        local type = config.Type

        -- Place the model.
        local model = item.Model:Clone()
        model.Parent = plot.Items
        model.Name = name
        model:SetAttribute("ItemType",type)
        local yAngle = math.rad(math.clamp(yRotation,0,360))
        model:PivotTo(CFrame.new(position)*CFrame.Angles(0,yAngle,0))

        -- Variables
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {workspace.Nodes,plot.Drops,model,filteredModel}

        -- Validate placement.
        local isPlacementValid = ignoreValidation or PlacementUtility.isPlacementValid(plot,model,overlapParams)
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
                        dropDelay = config.DropDelay;
                        dropPropieties = config.DropPropieties;
                    })
                end;
                Belt = function()
                    model.Belt:SetAttribute("Speed",config.BeltSpeed or 1)
                    model.Belt:SetAttribute("Slipperiness",config.BeltSlipperiness or 10)
                end;
                Forge = function()
                    model.Seller:SetAttribute("SellMultiplier",config.SellMultiplier)
                end;
                Upgrader = function()
                    model.Upgrader:SetAttribute("BoostType",config.BoostType or "Additive")
                    model.Upgrader:SetAttribute("BoostValue",config.BoostValue or 1) 
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

local function checkItemPrimaryPart(item,folder)
    if not item.PrimaryPart then
        local root = item:FindFirstChild("Root")
        if root then
            item.PrimaryPart = root
        else
            warn("CRITICAL: "..folder.Name.."'s model doesn't have a primary part, and there is no part named 'Root'.")
        end
    end
end

local function generateDefaultEdges(item)
    local root = item.PrimaryPart
    local size = root.Size
    local hX = size.X/2
    local hZ = size.Z/2
    local x = Vector3.xAxis
    local z = Vector3.zAxis
    local edgeBias = 0.1 -- So the raycasts of edges at the limits of the plot dont go through
    local bHX = (hX-edgeBias)
    local bHZ = (hZ-edgeBias)
    local positions = {
        -x*bHX + z*bHZ;
        x*bHX - z*bHZ;
        x*bHX + z*bHZ;
        -x*bHX - z*bHZ;
    }
    for _,pos in pairs(positions) do
        local edge = Instance.new("Attachment")
        edge.Name = "Edge"
        edge.Parent = root
        local heightBias = -Vector3.yAxis*size.Y/2
        local extraBias = Vector3.yAxis*0.1 -- So it's not exactlly on the plot, which causes the raycasting to go through
        edge.Position = pos+heightBias+extraBias
    end
end

local function setupItems()
    -- Missing primary part:
    local descendants = ReplicatedStorage.Assets:GetDescendants()
    for _,item in pairs(descendants) do
        if item:IsA("Model") then
            local folder = item.Parent
            if folder:IsA("Folder") then
                -- It's an item:
                checkItemPrimaryPart(item,folder)

                local anyEdge = item.PrimaryPart:FindFirstChild("Edge")
                if not anyEdge then
                    generateDefaultEdges(item)
                end
            end
        end
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

    setupItems()
end

return ServerPlacement