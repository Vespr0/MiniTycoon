local PlacementInstance = {}
PlacementInstance.__index = PlacementInstance

-- Services --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders --
local Events = ReplicatedStorage.Events
local Nodes = workspace:WaitForChild("Nodes")

-- Modules --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
local AssetsDealer = require(Shared.AssetsDealer)
local PlacementUtility = require(Shared.Plots.PlacementUtility)
local Signal = require(Packages.signal)
local PlacementMenuUi = require(script.Parent.Parent.Parent.Ui.Modules.PlacementMenu)
local FXManager = require(script.Parent.Parent.Parent.FX.FXManager)
local ClientPlacement = require(script.Parent.ClientPlacement)
local ClientInput = require(script.Parent.Parent.Parent.Input.ClientInput)

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Constants --
local HIGHLIGHT = Instance.new("Highlight")
local VALID_PLACEMENT_COLOR = Color3.fromRGB(255, 255, 255)
local INVALID_PLACEMENT_COLOR = Color3.fromRGB(255, 51, 112)
local LERP_TIME = 1 / 20

-- Debug flags --
local DISABLE_GRID_SNAPPING = false
local DISABLE_LERPING = false

function PlacementInstance.new(itemName, model, isMoving)
	local self = setmetatable({}, PlacementInstance)
	
	-- Properties
	self.itemName = itemName
	self.isMoving = isMoving or false
	self.yRotation = 0
	self.validPlacement = false
	self.goalCFrame = nil
	
	-- Trove for cleanup
	self.trove = require(Packages.trove).new()
	
	-- Initialize
	self:setup(model)
	self:setupInput()
	self:startPlacementLoop()
	
	return self
end

function PlacementInstance:setup(model)
	-- Get plot and item data
	self.plot = PlacementUtility.GetClientPlot()
	self.plotRoot = self.plot:WaitForChild("Root")
	self.item = AssetsDealer.GetItem(self.itemName)
	self.config = require(self.item.config)
	
	-- Handle moving vs placing
	self.originalModel = nil
	self.localID = 0
	
	if self.isMoving then
		self.originalModel = model
		self.originalModel.Parent = ReplicatedStorage.Temp
		model = model:Clone()
		self.localID = model:GetAttribute("LocalID")
	end
	
	-- Setup model
	self.model = model or self.item.Model:Clone()
	self.model.Parent = Nodes
	self.model:SetAttribute("ItemName", self.itemName)
	self.modelRoot = self.model.PrimaryPart
	
	PlacementUtility.GhostModel(self.model)
	
	-- Setup highlight
	self.highlight = HIGHLIGHT:Clone()
	self.highlight.Parent = self.model
	self.highlight.Enabled = true
	self:_switchHighlight(false)
	
	-- Setup overlap params
	self.overlapParams = OverlapParams.new()
	self.overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	self.overlapParams.FilterDescendantsInstances = { workspace.Nodes, self.model, self.plot.Drops }
	
	-- Calculate grid size
	self.gridSize = self:_calculateGridSize()
	
	-- Set mouse filter
	Mouse.TargetFilter = Nodes
end

function PlacementInstance:_calculateGridSize()
	if not self.modelRoot then
		error("No root part")
	end
	
	local size = self.modelRoot.Size
	local xIsEven = size.X % 2 == 0
	local zIsEven = size.Z % 2 == 0
	
	return (xIsEven and zIsEven) and 1 or 0.5
end

function PlacementInstance:_switchHighlight(valid)
	local color = valid and VALID_PLACEMENT_COLOR or INVALID_PLACEMENT_COLOR
	self.highlight.FillColor = color
	self.highlight.OutlineColor = color
end

function PlacementInstance:setupInput()
	local PlacementInput = require(script.Parent.Parent.Parent.Input.InputModules.PlacementInput)
	
	self.trove:Connect(PlacementInput.RotateEvent, function()
		self:rotate()
	end)
	
	self.trove:Connect(PlacementInput.CancelEvent, function()
		self:abort()
	end)
	
	self.trove:Connect(PlacementInput.PlaceEvent, function()
		if self.validPlacement then
			self:place()
		end
	end)
	
	self.trove:Connect(PlacementMenuUi.CancelButtonClicked, function()
		self:abort()
	end)
	
	self.trove:Connect(PlacementMenuUi.RotateButtonClicked, function()
		self:rotate()
	end)
end

function PlacementInstance:startPlacementLoop()
	self.trove:Connect(RunService.RenderStepped, function(deltaTime)
		self:update(deltaTime)
		self:validatePlacement()
	end)
end

function PlacementInstance:update(deltaTime)
	-- Ignore placement menu if you are on mobile
	local updatePosition = true
	if ClientInput.HasTouch then
		if PlacementMenuUi.IsCursorOverMenu() then
			updatePosition = false
		end
	end

	local finalPos
	if updatePosition then
		print("omagad")
		local hit = Mouse.Hit.Position
		local plotHeight = self.plotRoot.Position.Y + self.plotRoot.Size.Y / 2
		local pos = Vector3.new(hit.X, plotHeight, hit.Z)
		local heightBias = Vector3.yAxis * self.modelRoot.Size.Y / 2
		
		-- Apply grid snapping
		finalPos = DISABLE_GRID_SNAPPING and (pos + heightBias)
			or PlacementUtility.SnapPositionToGrid(pos + heightBias, self.gridSize, true)
	else	
		print("jesus.")
		finalPos = self.modelRoot.CFrame.Position
	end

	self.goalCFrame = CFrame.new(finalPos) * CFrame.Angles(0, math.rad(self.yRotation), 0)
	
	-- Apply lerping
	local targetCFrame = DISABLE_LERPING and self.goalCFrame 
		or self.modelRoot.CFrame:Lerp(self.goalCFrame, deltaTime / LERP_TIME)
	
	self.model:PivotTo(targetCFrame)
end

function PlacementInstance:validatePlacement()
	self.validPlacement = PlacementUtility.isPlacementValid(self.plot, self.model, self.overlapParams, self.config)
	
	-- Only update highlight on clean angles to avoid flashing during rotation
	local angleY = self.modelRoot.Orientation.Y
	if angleY % 90 == 0 then
		self:_switchHighlight(self.validPlacement)
	end
end

function PlacementInstance:rotate()
	self.yRotation += 90
	if self.yRotation > 360 then
		self.yRotation = 90
	end
	ClientPlacement.PlacementRotated:Fire()
end

function PlacementInstance:place()
	if not self.validPlacement then
		return
	end
	
	self:cleanup()
	PlacementMenuUi.Close()
	
	if self.isMoving then
		local result = Events.Move:InvokeServer(self.localID, self.goalCFrame.Position, self.yRotation)
		if not result then
			self.originalModel.Parent = self.plot.Items
		end
		FXManager.AnimatePlacement({
			model = PlacementUtility.WaitForItemFromLocalID(self.plot.Items, self.localID)
		})
		ClientPlacement.PlacementFinished:Fire(result)
		return result
	else
		local localID = Events.Place:InvokeServer(self.itemName, self.goalCFrame.Position, self.yRotation)
		FXManager.AnimatePlacement({
			model = PlacementUtility.WaitForItemFromLocalID(self.plot.Items, localID)
		})
		ClientPlacement.PlacementFinished:Fire(localID)
		return localID
	end
end

function PlacementInstance:abort()
	self:_cleanup()
	PlacementMenuUi.Close()
	
	-- Restore original model if moving and cancelled
	if self.isMoving and self.originalModel then
		self.originalModel.Parent = self.plot.Items
	end
	
	ClientPlacement.PlacementAborted:Fire()
end

function PlacementInstance:cleanup()
	self.model:Destroy()
	self.trove:Clean()
end

function PlacementInstance:destroy()
	self:cleanup()
end

return PlacementInstance