local PlotManager = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Events = ReplicatedStorage.Events
local Shared = ReplicatedStorage.Shared

local Plots = workspace:WaitForChild("Plots")
-- Modules --
local AssetsDealer = require(Shared.AssetsDealer)
local PlotLoader = require(Server.Plots.PlotLoader)
local PlotUtility = require(Shared.Plots.PlotUtility)

function PlotManager.SetPlayerPlot(player,name)
	local errorString = ", no Plot was assigned."
	if not player then
		error("Player is missing or nil"..errorString)
	end
	if not name then
		error("No Plot name given"..errorString)
	end
	--PlotManager.ClearPlayerPlot(player)
	player:SetAttribute("Plot",name)
	local plot = Plots:FindFirstChild(name)
	if not plot then
		error("Couldn't find any Plot named "..name..errorString)
	end	
	plot:SetAttribute("OwnerID",player.UserId)
	plot:SetAttribute("DropCounter",0)
	task.spawn(function()
		repeat task.wait(.2)
        until player.Character
		player.Character.PrimaryPart.CFrame = CFrame.new(plot.Root.Position+Vector3.yAxis*6)
	end)
end

function PlotManager.ClearPlayerPlot(player)
	local errorString = ", no Plot was cleared."
	if not player then
		error("player is missing or nil"..errorString)
	end
	local plotName = player:GetAttribute("Plot")
	if plotName then
		local plot = Plots:FindFirstChild(plotName.Value)
		if not plot then
			error("Couldn't find any Plot named "..plotName.Value..errorString)
		end
		plot:SetAttribute("OwnerID",0)
		plot.Items:ClearAllChildren()
	end
end

local function setupPlotFolders()
	for _,folder in pairs(Plots:GetChildren()) do
		-- Folders --
		local ItemsFolder = Instance.new("Folder"); ItemsFolder.Parent = folder; ItemsFolder.Name = "Items";
		local TilesFolder = Instance.new("Folder"); TilesFolder.Parent = folder; TilesFolder.Name = "Tiles";
		local DropsFolder = Instance.new("Folder"); DropsFolder.Parent = folder; DropsFolder.Name = "Drops";
		-- Attributes --
		folder:SetAttribute("OwnerID",0)
		-- Values --
		local PartsValue = Instance.new("IntValue"); PartsValue.Parent = folder; PartsValue.Name = "Parts";
	end
end

function PlotManager.Setup()
	setupPlotFolders()
    local function loadPlayer(player)
		task.defer(function()
			PlotManager.SetPlayerPlot(player,PlotUtility.FindAvaiablePlot())
			repeat task.wait(.2) until player:GetAttribute("DataLoaded")
			PlotLoader.Load(player)
		end)
    end
	for _,player in pairs(Players:GetChildren()) do
		loadPlayer(player)
	end
	Players.PlayerAdded:Connect(function(player)
		loadPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		PlotManager.ClearPlayerPlot(player)
	end)
end

return PlotManager
