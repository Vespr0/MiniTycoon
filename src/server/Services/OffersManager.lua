local OffersManager = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Server = ServerScriptService:WaitForChild("Server")
local Events = ReplicatedStorage.Events
local Shared = ReplicatedStorage.Shared

-- Modules --
-- local AssetsDealer = require(Shared.AssetsDealer)
local OffersAccess = require(Server.Data.DataAccessModules.OffersAccess)
local ItemsAccess = require(Server.Data.DataAccessModules.ItemsAccess)
local CashAccess = require(Server.Data.DataAccessModules.CashAccess)
local LevelingAccess = require(Server.Data.DataAccessModules.LevelingAccess)
local OnboardingAccess = require(Server.Data.DataAccessModules.OnboardingAccess)
local OffersUtil = require(script.Parent.OffersUtil)
local EconomyLogger = require(Server.Analytics.EconomyLogger)

local IsStudio = RunService:IsStudio()

local MINUTE = 60
local HOUR = MINUTE*60
local OFFER_DURATION = IsStudio and MINUTE/4 or MINUTE*15

local function getOfferFromItem(offers,itemName)
    for i = 1,#offers do
        if offers[i].ID == itemName then
            return offers[i]
        end
    end
    return false
end

local function getRequest(player)
    if not player then return end

    local oldOffers,oldExpiration = OffersAccess.GetOffers(player)
    local missingOffers = not oldOffers or not oldExpiration

    local function sendNew()
        warn("Offers expired, resetting.")
        local expiration = workspace:GetServerTimeNow() + OFFER_DURATION

        local offers = OffersUtil.GenerateOffers(player)

        local detailedOffers = {}
        for i = 1,#offers do
            local offer = offers[i]
            detailedOffers[i] = {ItemName = offer.ItemName,Price = offer.Price,Bought = false}
        end
        
        OffersAccess.SetOffers(player,detailedOffers,expiration)

        return {
            offers = detailedOffers;
            expiration = expiration;
        }
    end

    local function sendOld()
        return {
            offers = oldOffers;
            expiration = oldExpiration;
        }
    end 

    if missingOffers then
        return sendNew()
    else
        local expired = oldExpiration <= workspace:GetServerTimeNow()

        if expired then
            return sendNew()
        end

        return sendOld()
    end
end

local function BuyRequest(player,args)
    local offerID = args.offerID
    if not player or not offerID then return end

    local offers,expiration = OffersAccess.GetOffers(player)
    if not offers or not expiration then return false,"Failed to get offers." end
    local expired = expiration <= workspace:GetServerTimeNow()

    local cash = CashAccess.GetCash(player)
    if not expired then
        local offer = offers[offerID]
        if offer then
            local itemName = offer.ItemName
            local canAfford = cash >= offer.Price
            local bought = offer.Bought

            if bought then
                return false,"Offer already bought."
            end

            if canAfford then
                -- Take cash
                CashAccess.TakeCash(player,offer.Price)
                -- Give item
                ItemsAccess.GiveStorageItems(player,itemName,1)
                -- Mark offer as bought
                OffersAccess.MarkOfferAsBought(player,offerID)
                -- Give exp
                LevelingAccess.GiveExp(player,offer.Price)
                -- Funnel event for first offer purchase
                
                -- Log onboarding step
                OnboardingAccess.Complete(player, "FirstOfferPurchase")

                -- Log economy shop purchase
                local endingCash = CashAccess.GetCash(player) - offer.Price
                EconomyLogger.LogShopPurchase(player, itemName, "Market",offer.Price, endingCash)

                return true
            else
                return false,"Not enough cash."
            end
        else
            return false,"Invalid offer."
        end
    else
        return false,"Offer expired."
    end
end

local function readOffersRequest(player,type,args)
    if type == "Get" then
        return getRequest(player)
    elseif type == "Buy" then
        return BuyRequest(player,args)
    end
    return false,"Invalid request type."
end

function OffersManager.Setup()
	Events.Offers.OnServerInvoke = readOffersRequest
end

return OffersManager
