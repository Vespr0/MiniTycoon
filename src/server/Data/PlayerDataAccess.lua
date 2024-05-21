local PlayerDataAccess = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
local ServerPlayerData = ServerStorage:WaitForChild("ServerPlayerData")

-- Modules --
local DataStoreModule = require(Packages.suphisdatastoremodule)
local DataUtility = require(Shared.Data.DataUtility)
local Signal = require(Packages.signal)

-- Signals
PlayerDataAccess.PlayerDataChanged = Signal.new()

-- Constants --
local ERRORS = {
    accessAttemptFailedNil = "📋 Trying to access datastore, but it is nil.";
    accessAttemptFailedClosed = "📋 Trying to access datastore, but it is closed.";
    accessFailed = "📋 Failed to access datastore."
}
local CASH_QUEUE_DELAY = 0.3

local function isDataStoreAccessible(dataStore)
    if dataStore == nil then
        return false,ERRORS.accessAttemptFailedNil
    end
    -- Make sure the session is open or the value will never get saved
    if dataStore.State ~= true then 
        return false,ERRORS.accessAttemptFailedClosed
    end
    return true
end

local function accessDataStore(name,key,r)
    if r <= 0 then return end
    local dataStore = DataStoreModule.find(name or DataUtility.GetDataScope("Player"),key)
    local success,error = isDataStoreAccessible(dataStore)
    if not success then
        warn(error.." Retrying...")
        task.wait(.5)
        accessDataStore(name,key,r-1)
        return
    end
    return dataStore
end

local cashQueue = {
    -- [player.UserId] = {amount,amount...}
}
function PlayerDataAccess.AddCashToQueue(player,amount)
    if not cashQueue[player.UserId] then
        cashQueue[player.UserId] = {}
    end
    table.insert(cashQueue[player.UserId],amount)
    -- print(cashQueue[player.UserId],amount)
end

function PlayerDataAccess.GiveCash(player,amount)
    --local dataFolder = ServerPlayerData[player.UserId]
    local dataStore = accessDataStore(nil,player.UserId,3)
    if not dataStore then return end
    -- Value.
    --dataFolder.Cash.Value += amount
    -- Database entry.
    dataStore.Value.Cash += amount
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Cash"),dataStore.Value.Cash)
end

-- Placed Items.

--[[
    Placed item standard:

    [localID]:
        [1] = positionX;
        [2] = positionY;
        [3] = postiionZ;
        [4] = itemID;
        [5] = yRotation;
--]]
function PlayerDataAccess.GetFull(player)
    local dataStore = accessDataStore(nil,player.UserId,4)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    return dataStore.Value
end

function PlayerDataAccess.GetPlacedItems(player)
    local dataStore = accessDataStore(nil,player.UserId,3)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    return dataStore.Value.PlacedItems
end

function PlayerDataAccess.GetPlacedItem(player,localID)
    local dataStore = accessDataStore(nil,player.UserId,3)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Getting the placed item from the item's localID.
    return dataStore.Value.PlacedItems[localID]
end

function PlayerDataAccess.RegisterPlacedItem(player,localID,localPosition,itemID,yRotation)
    local dataStore = accessDataStore(nil,player.UserId,3)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Database entry.
    local data = {[1] = localPosition.X,[2] = localPosition.Y,[3] = localPosition.Z,[4] = itemID,[5] = yRotation}
    dataStore.Value.PlacedItems[localID] = data
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("PlacedItem"),localID,data)
end

function PlayerDataAccess.RemovePlacedItem(player,localID)
    local dataStore = accessDataStore(nil,player.UserId,3)
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
function PlayerDataAccess.GiveStorageItems(player,itemID,amount)
    --local dataFolder = ServerPlayerData[player.UserId]
    local dataStore = accessDataStore(nil,player.UserId,3)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
--[[    -- Value.
    local item = Instance.new("IntValue")
    item.Name = itemID
    item.Value = amount
    item.Parent = dataFolder.Storage]]
    -- Database entry.
    if not dataStore.Value.Storage[itemID] then
        dataStore.Value.Storage[itemID] = amount
    else
        dataStore.Value.Storage[itemID] += amount
    end
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Storage"),itemID,dataStore.Value.Storage[itemID]+amount)
end

function PlayerDataAccess.ConsumeStorageItems(player,itemID,amount)
    --local dataFolder = ServerPlayerData[player.UserId]
    local dataStore = accessDataStore(nil,player.UserId,3)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Setting database entry to nil to remove it.
    --local item = dataFolder.Storage:FindFirstChild(itemID)
    local count = dataStore.Value.Storage[itemID]
    if amount >= count then
        -- Value.
        --item:Destroy()
        -- Database entry.
        dataStore.Value.Storage[itemID] = nil
        PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Storage"),itemID,-1)
    else
        -- Value.
        --item.Value -= amount
        -- Database entry.
        dataStore.Value.Storage[itemID] = count-amount
        PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Storage"),itemID,count-amount)
    end
end

function PlayerDataAccess.GetStorageItem(player,itemID)
    local dataStore = accessDataStore(nil,player.UserId,3)
    if not dataStore then error(ERRORS.accessFailed.."#"..player.UserId); return end
    -- Getting the storage item from item's ID.
    return dataStore.Value.Storage[itemID]
end

-- Setup --
function PlayerDataAccess.Setup()
    local function erasePlayer(player)
        if cashQueue[player.UserId] then
            for k in pairs(cashQueue[player.UserId]) do
                cashQueue[player.UserId][k] = nil
            end
        end
    end
    Players.PlayerRemoving:Connect(function(player)
        erasePlayer(player)
    end)
    -- Cash queue.
    task.defer(function()
       while true do
            task.wait(CASH_QUEUE_DELAY)
            for userId,playerCashQueue in cashQueue do
                if #playerCashQueue < 1 then continue end
                local player = Players:GetPlayerByUserId(userId)
                if not player then continue end
                local amount = 0
                for index,value in pairs(playerCashQueue) do
                    amount += value
                    table.remove(playerCashQueue,index)
                end
                PlayerDataAccess.GiveCash(player,amount)
            end
        end
    end)
end

return PlayerDataAccess