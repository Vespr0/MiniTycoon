local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
-- Load assets --
workspace:WaitForChild("Assets").Parent = ReplicatedStorage
-- Load modules --

-- TODO: Automate this , what the hell why am i calling setup manually lmao

-- Setup Plots and Placement
require(script.Plots.PlotManager).Setup()
require(script.Plots.ServerPlacement).Setup()
require(script.Plots.TilingManager).Setup()

-- Setup Data
require(script.PlayerManager).Setup()
require(script.Data.PlayerDataStore).Setup()
require(script.Data.PlayerDataManager).Setup()
require(script.Data.PlayerOrderedDataManager).Setup()

-- Setup Services
require(script.Services.MarketManager).Setup()
require(script.Services.OffersManager).Setup()
require(script.Services.StocksSimulator).Setup()
require(script.Services.ControlPanelManager).Setup()

-- Tests
local TestingManager = require(script.TestingManager)
if RunService:IsStudio() then
    -- Run all tests in the Tests folder
    -- TestingManager.RunAll()
end