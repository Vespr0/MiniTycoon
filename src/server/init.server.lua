local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
-- Load assets --
workspace:WaitForChild("Assets").Parent = ReplicatedStorage
-- Load modules --

-- Setup Plots and Placement
require(Server.Plots.PlotManager).Setup()
require(Server.Plots.ServerPlacement).Setup()
require(Server.Plots.TilingManager).Setup()

-- Setup Data
require(Server.PlayerManager).Setup()
require(Server.Data.PlayerDataStore).Setup()
require(Server.Data.PlayerDataManager).Setup()

-- Setup Services
require(Server.Services.ShopManager).Setup()
require(Server.Services.StocksSimulator).Setup()
require(Server.Services.ControlPanelManager).Setup()
