local ItemsAccess = {}

local LevelingAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local DataUtility = DataAccess.DataUtility

-- Constants --
local ERRORS = DataAccess.Errors

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
    local player = DataAccess.GetParameters(...)
	if not player then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    return dataStore.Value.PlacedItems
end

function ItemsAccess.GetPlacedItem(...)
	local player, localID = DataAccess.GetParameters(...)
	if not (player and localID) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Getting the placed item from the item's localID.
    return dataStore.Value.PlacedItems[localID]
end

function ItemsAccess.RegisterPlacedItem(...)
	local player, localID, localPosition, itemName, yRotation = DataAccess.GetParameters(...)
	if not (player and localID and localPosition and itemName and yRotation) then return end


    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Database entry.
    local data = {[1] = localPosition.X,[2] = localPosition.Y,[3] = localPosition.Z,[4] = itemName,[5] = yRotation}
    dataStore.Value.PlacedItems[localID] = data
    DataAccess.PlayerDataChanged:Fire(player,"PlacedItem",localID,data)
end

function ItemsAccess.RemovePlacedItem(...)
	local player, localID = DataAccess.GetParameters(...)
	if not (player and localID) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Setting database entry to nil to remove it.
    dataStore.Value.PlacedItems[localID] = nil
    DataAccess.PlayerDataChanged:Fire(player,"PlacedItem",localID,nil)
end

-- Storage Items.

--[[
    storage item standard:

    [id] = amount
--]]
function ItemsAccess.GiveStorageItems(...)
	local player, itemName, amount = DataAccess.GetParameters(...)

	local player = player or error("Player not specified")
	local itemName = tostring(itemName) or error("Item Name not specified")
	local amount = tonumber(amount) or 1 and warn("Amount not specified, default: 1")

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end

    -- Database entry.
    if not dataStore.Value.Storage[itemName] then
        dataStore.Value.Storage[itemName] = amount
    else
        dataStore.Value.Storage[itemName] += amount
    end
    DataAccess.PlayerDataChanged:Fire(player,"Storage",itemName,dataStore.Value.Storage[itemName])
end

function ItemsAccess.ConsumeStorageItems(...)
	local player, itemName, amount = DataAccess.GetParameters(...)

	local player = player or error("Player not specified")
	local itemName = tostring(itemName) or error("Item Name not specified")
	local amount = tonumber(amount) or 1 and warn("Amount not specified, default: 1")

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end

    local count = dataStore.Value.Storage[itemName]
    if amount >= count then
        -- Remove it.
        dataStore.Value.Storage[itemName] = nil
        DataAccess.PlayerDataChanged:Fire(player,"Storage",itemName,-1)
    else
        -- Decrease value based on amount.
        dataStore.Value.Storage[itemName] = count-amount
        DataAccess.PlayerDataChanged:Fire(player,"Storage",itemName,count-amount)
    end
end

function ItemsAccess.GetStorageItem(...)
	local player, itemName = DataAccess.GetParameters(...)
	if not (player and itemName) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    -- Getting the storage item from item's name.
    return dataStore.Value.Storage[itemName]
end

-- TODO : idk if this is corrent and eitherway it doesnt update the client
-- function ItemsAccess.WipeAllItems(...)
--     local player = DataAccess.GetParameters(...)
-- 	if not player then return end
	
--     local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
--     if not dataStore then return end
--     -- Setting database entry to nil to remove it.
--     for k,v in pairs(dataStore.Value.Storage) do
--         dataStore.Value.Storage[k] = nil
--     end
--     --DataAccess.PlayerDataChanged:Fire(player,"Storage"),nil,nil)
-- end

function ItemsAccess.Setup()
    -- Players.PlayerAdded:Connect(function(player)
    --     ItemsAccess.WipeAllItems(player)
    -- end)
end

return ItemsAccess