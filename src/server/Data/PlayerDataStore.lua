local PlayerDataStore = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Folders --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
-- Modules --
local DataStoreModule = require(Packages.suphisdatastoremodule)
local DataUtility = require(Shared.Data.DataUtility)

PlayerDataStore.DataTemplate = {
	-- Basic Data --
	Level = 1,
	Exp = 0,
	Cash = 0,
	-- Items --
	Storage = {},
	PlacedItems = {},
	-- Plot --
	Plot = {
		PlotLevel = 1,
	},
	-- Session --
	Session = {
		FirstPlayed = nil,
		LastPlayed = nil,
		TimePlayed = 0,
	},
	-- Services --
	Services = {
		Offers = nil,
		OffersExpiration = nil,
	},
	-- Stats --
	Stats = {
		OffersBought = 0,
	},

	Tutorial = {
		TutorialFinished = false,
		SavedTutorialPhase = 1,
	},
	-- Onboarding steps tracking --
	Onboarding = {},
}

local function stateChanged(state, dataStore)
	while dataStore.State == false do
		if dataStore:Open(PlayerDataStore.DataTemplate) ~= "Success" then
			warn("Failed to open player datastore, retrying...")
			task.wait(6)
		end
	end
end

function PlayerDataStore.Setup()
	-- Player joins.
	Players.PlayerAdded:Connect(function(player)
		local dataStore = DataStoreModule.new(DataUtility.GetDataScope("Player"), player.UserId)
		dataStore.StateChanged:Connect(stateChanged)
		stateChanged(dataStore.State, dataStore)
	end)
	-- Player leaves.
	Players.PlayerRemoving:Connect(function(player)
		local dataStore = DataStoreModule.find(DataUtility.GetDataScope("Player"), player.UserId)
		-- If the player leaves, the datastore object is destroyed, allowing the retry loop to stop.
		if dataStore ~= nil then
			dataStore:Destroy()
		end
	end)
end

return PlayerDataStore
