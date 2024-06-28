local CashAccess = {}

-- Services --
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Modules --
local PlayerDataAccess = require(script.Parent.Parent.PlayerDataAccess)
local DataUtility = PlayerDataAccess.DataUtility
local LevelingAccess = require(script.Parent.LevelingAccess)

-- Constants -- 
local CASH_QUEUE_DELAY = 0.3

-- Variables --
local cashQueue = {
    -- [player.UserId] = {amount,amount...}
}

local function updateClientCash(player,amount)
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("Cash"),amount)
end

function CashAccess.AddCashToQueue(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local amount = args[2]

    if not cashQueue[player.UserId] then
        cashQueue[player.UserId] = {}
    end
    table.insert(cashQueue[player.UserId],amount)
end

function CashAccess.GiveCash(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local amount = args[2]
    local expGain = args[3]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    -- Set values.
    dataStore.Value.Cash += amount
    
    -- Exp gain (if expressed)
    if expGain then
        LevelingAccess.GiveExp(player, amount)
    end

    updateClientCash(player,dataStore.Value.Cash)
end

function CashAccess.TakeCash(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local amount = args[2]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    -- Set values.
    dataStore.Value.Cash -= amount
    
    updateClientCash(player,dataStore.Value.Cash)
end

function CashAccess.GetCash(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end
    return dataStore.Value.Cash
end

function CashAccess.Setup()
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
                CashAccess.GiveCash(player,amount,true)
            end
        end
    end)

    local function erasePlayer(player)
        if cashQueue[player.UserId] then
            for k in pairs(cashQueue[player.UserId]) do
                cashQueue[player.UserId][k] = nil
            end
        end
    end
    Players.PlayerRemoving:Connect(function(player)
        if RunService:IsStudio() then
            CashAccess.GiveCash(player,10^3,false)
        end
        erasePlayer(player)
    end)
end

return CashAccess
