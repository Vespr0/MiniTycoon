local ItemsAccess = {}

local LevelingAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local PlayerDataAccess = require(script.Parent.Parent.PlayerDataAccess)
local DataUtility = PlayerDataAccess.DataUtility

-- Constants --
local ERRORS = PlayerDataAccess.Errors

-- Placed Items.

--[[
    Placed item standard:

    [localID]:
        [1] = positionX;
        [2] = positionY;
        [3] = postiionZ;
        [4] = itemName;
        [5] = yRotation;
--]]
function ItemsAccess.GetPlacedItems(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    return dataStore.Value.PlacedItems
end

function ItemsAccess.GetPlacedItem(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local localID = args[2]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Getting the placed item from the item's localID.
    return dataStore.Value.PlacedItems[localID]
end

function ItemsAccess.RegisterPlacedItem(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local localID = args[2]
    local localPosition = args[3]
    local itemName = args[4]
    local yRotation = args[5]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Database entry.
    local data = {[1] = localPosition.X,[2] = localPosition.Y,[3] = localPosition.Z,[4] = itemName,[5] = yRotation}
    dataStore.Value.PlacedItems[localID] = data
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("PlacedItem"),localID,data)
end

function ItemsAccess.RemovePlacedItem(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local localID = args[2]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Setting database entry to nil to remove it.
    dataStore.Value.PlacedItems[localID] = nil
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("PlacedItem"),localID,nil)
end

-- Storage Items.

--[[
    storage item standard:

    [id] = amount
--]]
function ItemsAccess.GiveStorageItems(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1] or error("Player not specified")
    local itemName = tostring(args[2]) or error("Item Name not specified")
    local amount = tonumber(args[3]) or 1 and warn("Amount not specified, default: 1")

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end

    warn(dataStore.Value.Storage)
    -- Database entry.
    if not dataStore.Value.Storage[itemName] then
        dataStore.Value.Storage[itemName] = amount
    else
        dataStore.Value.Storage[itemName] += amount
    end
    warn("Set value to "..itemName.." as "..dataStore.Value.Storage[itemName],dataStore.Value.Storage)
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Storage"),itemName,dataStore.Value.Storage[itemName])
end

function ItemsAccess.ConsumeStorageItems(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1] or error("Player not specified")
    local itemName = tostring(args[2]) or error("Item Name not specified")
    local amount = tonumber(args[3]) or 1 and warn("Amount not specified, default: 1")

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end

    local count = dataStore.Value.Storage[itemName]
    if amount >= count then
        -- Remove it.
        dataStore.Value.Storage[itemName] = nil
        PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Storage"),itemName,-1)
    else
        -- Decrease value based on amount.
        dataStore.Value.Storage[itemName] = count-amount
        PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Storage"),itemName,count-amount)
    end
end

function ItemsAccess.GetStorageItem(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local itemName = args[2]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    -- Getting the storage item from item's name.
    return dataStore.Value.Storage[itemName]
end

-- TODO : idk if this is corrent and eitherway it doesnt update the client
function ItemsAccess.WipeAllItems(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    -- Setting database entry to nil to remove it.
    for k,v in pairs(dataStore.Value.Storage) do
        dataStore.Value.Storage[k] = nil
    end
    --PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Storage"),nil,nil)
end

function ItemsAccess.Setup()

    -- Players.PlayerAdded:Connect(function(player)
    --     ItemsAccess.WipeAllItems(player)
    -- end)
end

return ItemsAccess