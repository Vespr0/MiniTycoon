local CashAccess = {}

-- Services --
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local DataUtility = DataAccess.DataUtility
local LevelingAccess = require(script.Parent.LevelingAccess)
local FunnelsLogger = require(script.Parent.Parent.Parent.Analytics.FunnelsLogger)

-- Constants -- 
local CASH_QUEUE_DELAY = 0.3

-- Variables --
local cashQueue = {
    -- [player.UserId] = {amount,amount...}
}

local function updateClientCash(player,amount)
    DataAccess.PlayerDataChanged:Fire(player,"Cash",amount)
end

function CashAccess.AddCashToQueue(...)
    local player, amount = DataAccess.GetParameters(...)
	if not (player and amount) then return end
	
    if not cashQueue[player.UserId] then
        cashQueue[player.UserId] = {}
    end
    table.insert(cashQueue[player.UserId],amount)
end

function CashAccess.GiveCash(...)
	local player, amount, expGain = DataAccess.GetParameters(...)
	if not (player and amount) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    -- Set values.
    dataStore.Value.Cash += amount
    
    -- Exp gain (if expressed)
    if expGain then
        LevelingAccess.GiveExp(player, amount)
    end

    -- Funnel log for onboarding step 3
    FunnelsLogger.LogOnboarding(player, "FirstCashEarned")

    updateClientCash(player,dataStore.Value.Cash)
end

function CashAccess.TakeCash(...)
	local player, amount = DataAccess.GetParameters(...)
	if not (player and amount) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    -- Set values.
    dataStore.Value.Cash -= amount
    
    updateClientCash(player,dataStore.Value.Cash)
end

function CashAccess.GetCash(...)
	local player = DataAccess.GetParameters(...)
	if not player then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
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
            -- Reset cash
            CashAccess.GiveCash(player, 1000, true)
            -- CashAccess.TakeCash(player,CashAccess.GetCash(player))
        end
        erasePlayer(player)
    end)
end

return CashAccess
