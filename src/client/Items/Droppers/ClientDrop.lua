local ClientDrop = {}
ClientDrop.__index = ClientDrop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Events = ReplicatedStorage.Events
local Packages = ReplicatedStorage.Packages

local AssetsDealer = require(Shared.AssetsDealer)
local ItemUtility = require(Shared.Items.ItemUtility)
local DropUtil = require(Shared.Items.Droppers.DropUtil)
local _SoundManager = require(Shared.Sound.SoundManager)
local FXManager = require(script.Parent.Parent.Parent.FX.FXManager)
local _Signal = require(Packages.signal)
local CashDisplay = require(script.Parent.Parent.Parent.Ui.Modules.CashDisplay)

function ClientDrop.new(properties, params)
	local drop = setmetatable({}, ClientDrop)
	-- Instance --
	drop.instance = params.instance
	--drop.instance.Transparency = 1
	drop.plot = params.plot
	drop.localID = params.localID
	drop.partID = params.partID
	drop.properties = properties
	drop.productType = params.productType
	drop.productQuantity = params.productQuantity

	-- Mesh --
	drop.mesh = AssetsDealer.GetMesh(properties.mesh)
	drop.mesh.Parent = workspace
	drop.mesh.Name = "Mesh"
	drop.mesh.Size = Vector3.one / 100
	drop.mesh.Color = drop.instance.Color

	drop.mesh.CanCollide = false
	drop.mesh.CanQuery = false
	drop.mesh.CanTouch = false
	drop.mesh.Massless = true
	drop.mesh.Anchored = true

	drop.tweenDelay = 0.1

	drop.mesh.CFrame = drop.instance.CFrame

	-- Client-side upgrader tracking
	drop.boosts = {}
	drop.steps = 0

	-- Cash display
	drop.cashDisplay = CashDisplay.new(drop.mesh)
	drop.cashDisplay:updateValue(drop:getValue())

	drop:grow()
	drop.connection = RunService.RenderStepped:Connect(function()
		local partExists = drop.instance and drop.instance.Parent
		local meshExists = drop.mesh and drop.mesh.Parent
		if partExists and meshExists and not drop.instance.Anchored then
			drop.steps += 1
			drop:step()
		else
			drop:fade()
		end
	end)

	drop.soldConnection = Events.DropReplication.OnClientEvent:Connect(
		function(ownerID, localID, partID, sold, forgeName, productType, productQuantity)
			if ownerID ~= drop.plot:GetAttribute("OwnerID") then
				return
			end

			if sold then
				if partID ~= drop.partID then
					return
				end

				drop:sell(forgeName)
				return
			end
			
			-- Handle new drop creation if this is for a new drop
			if not sold and productType and productQuantity then
				-- This would be handled by the client dropper system
				-- Just here for completeness of the event signature
			end
		end
	)

	return drop
end

function ClientDrop:getValue()
	local ProductsInfo = require(game.ReplicatedStorage.Shared.Items.ProductsInfo)
	warn(self.productType,self.productQuantity)
	local baseValue = ProductsInfo.Products[self.productType].BaseSellValue
	local totalValue = baseValue * self.productQuantity
	
	for _, boost in pairs(self.boosts) do
		totalValue = DropUtil.CalculateBoost(totalValue, boost.type, boost.value)
	end
	return totalValue
end

function ClientDrop:sell(forgeName)
	local config = ItemUtility.GetItemConfig(forgeName)

	local size = self.mesh.Size
	local color = config.SmeltEffect.Color

	FXManager.Smelt({ instance = self.mesh, size = size, color = color })
	task.wait(2.5)

	self:destroy()
end

function ClientDrop:fade()
	FXManager.Fade({ Instance = self.mesh, Time = 2 })
    self.cashDisplay:fade()
	task.wait(2)
    self:destroy()
end

function ClientDrop:destroy()
	self.connection:Disconnect()
	self.soldConnection:Disconnect()
	self.cashDisplay:destroy()
	self.mesh:Destroy()
end

function ClientDrop:grow()
	TweenService:Create(self.mesh, TweenInfo.new(math.min(0.6, self.instance.Size.Magnitude), Enum.EasingStyle.Sine), {
		Size = self.instance.Size,
	}):Play()
end

function ClientDrop:getUpgrader()
	local newBoosts = DropUtil.ProcessUpgraders(self.instance, self.plot, self.boosts)
	local hasNewBoosts = false

	-- Apply new boosts and trigger visual effects
	for localID, boost in pairs(newBoosts) do
		if not self.boosts[localID] then
			hasNewBoosts = true
		end
		self.boosts[localID] = boost
	end
	
	-- Update cash display with animation if new boosts were applied
	self.cashDisplay:updateValue(self:getValue(), hasNewBoosts)
end

function ClientDrop:step()
	self.mesh.CFrame = self.instance.CFrame

	-- Check for upgraders every few steps (similar to server)
	if self.steps % 2 == 0 then
		self:getUpgrader()
	end

	-- TweenService:Create(self.mesh,TweenInfo.new(self.tweenDelay,Enum.EasingStyle.Linear),{
	--     CFrame = self.instance.CFrame
	-- }):Play()
end

return ClientDrop
