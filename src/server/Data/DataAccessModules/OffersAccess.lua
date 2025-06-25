local OffersAccess = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local DataAccess = require(script.Parent.Parent.DataAccess)
local DataUtility = DataAccess.DataUtility

function OffersAccess.GetOffers(...)
	local player = DataAccess.GetParameters(...)
	if not player then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    local offers = dataStore.Value.Services.Offers
    local expiration = dataStore.Value.Services.OffersExpiration
    
    --print(player.UserId.." offers retrieved as ",offers)
    
    return offers,expiration
end

function OffersAccess.SetOffers(...)
	local player, offers, expiration = DataAccess.GetParameters(...)
	if not (player and offers and expiration) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
    if not dataStore then return end

    dataStore.Value.Services.Offers = offers
    dataStore.Value.Services.OffersExpiration = expiration

    --print(player.UserId.." offers updated as ",offers)

    -- Update
    DataAccess.PlayerDataChanged:Fire("OffersInfo",{Offers = offers,Expiration = expiration})

    return offers
end

function OffersAccess.MarkOfferAsBought(...)
	local player, offerID = DataAccess.GetParameters(...)
	if not (player and offerID) then return end

    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
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
    local dataStore = DataAccess.AccessDataStore(nil,player.UserId)
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