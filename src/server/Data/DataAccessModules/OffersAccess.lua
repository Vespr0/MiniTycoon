local OffersAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local PlayerDataAccess = require(script.Parent.Parent.PlayerDataAccess)
local DataUtility = PlayerDataAccess.DataUtility

function OffersAccess.GetOffers(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    local offers = dataStore.Value.Services.Offers
    local expiration = dataStore.Value.Services.OffersExpiration
    
    --print(player.UserId.." offers retrieved as ",offers)
    
    return offers,expiration
end

function OffersAccess.SetOffers(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local offers = args[2]
    local expiration = args[3]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    dataStore.Value.Services.Offers = offers
    dataStore.Value.Services.OffersExpiration = expiration

    --print(player.UserId.." offers updated as ",offers)

    -- Update
    PlayerDataAccess.PlayerDataChanged:Fire(player,DataUtility.GetTypeId("OffersInfo"),{Offers = offers,Expiration = expiration})

    return offers
end

function OffersAccess.MarkOfferAsBought(...)
    local args = PlayerDataAccess.GetParameters(...)
    if not args then return end

    local player = args[1]
    local offerID = args[2]

    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    local offers = dataStore.Value.Services.Offers

    for i = 1,#offers do
        if i == offerID then
            offers[i].Bought = true
        end
    end

    -- TODO: update client
    return true
end

function OffersAccess.WipeAllOffers(player)
    local dataStore = PlayerDataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    local offers = dataStore.Value.Services.Offers
    dataStore.Value.Services.OffersExpiration = 0

    for i = 1,#offers do
        offers[i] = nil
    end

    -- TODO: update client
end


function OffersAccess.Setup()
    Players.PlayerAdded:Connect(function(player)
        --OffersAccess.WipeAllOffers(player)
    end)
end

return OffersAccess