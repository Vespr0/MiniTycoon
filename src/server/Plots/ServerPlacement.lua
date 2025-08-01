local ServerPlacement = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Events = ReplicatedStorage.Events
local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server

-- Modules --
local PlacementUtility = require(Shared.Plots.PlacementUtility)
local AssetsDealer = require(Shared.AssetsDealer)
local ItemUtility = require(Shared.Items.ItemUtility)
local PlotUtility = require(Shared.Plots.PlotUtility)
-- Classes --
local ServerDropper = require(Server.Items.Droppers.ServerDropper)
local PlayerDataManager = require(Server.Data.PlayerDataManager)
local ItemsAccess = require(Server.Data.DataAccessModules.ItemsAccess)
local OnboardingAccess = require(Server.Data.DataAccessModules.OnboardingAccess)

local errors = {
	-- Arguments.
	InvalidArgumentType = "Invalid argument from client: ``&a`` argument is invalid.",
	-- Placement Validity.
	InvalidPositionAndRotation = "Invalid position and rotation from client.",
	-- Item Info.
	ItemNameDoesntExist = "Invalid item name from client: ``&a`` isn't a valid entry in the items archive.",
	-- Storage.
	PlayerDoesntHaveStorageItem = "Player requested placement but does not own the item.",
	-- Placed Items.
	PlayerDoesntHavePlacedItemToMove = "Invalid placed item localID: ``&a`` from player to move, no physical placed item.",
	PlayerDoesntHavePlacedItemInDatastoreToMove = "Invalid placed item localID: ``&a`` from player to move, placed item isn't in datastore.",
	PlayerDoesntHavePlacedItemToStore = "Invalid placed item localID: ``&a`` from player to store, no physical placed item.",
	PlayerDoesntHavePlacedItemInDatastoreToStore = "Invalid placed item localID: ``&a`` from player to store, placed item isn't in datastore.",
}

local function findAvaiableItemLocalID(folder)
	local id = 0
	while true do
		id += 1
		local avaiable = true
		for _, item in pairs(folder:GetChildren()) do
			if item:GetAttribute("LocalID") == id then
				avaiable = false
				break
			end
		end
		if not avaiable then
			continue
		end
		return id
	end
end

local function setModelStreamingMode(model: Model, player: Player?)
	model.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	model:AddPersistentPlayer(player)
end

function ServerPlacement.DisableQueries(model)
	for _, d in pairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			if d ~= model.PrimaryPart and d.Parent.Name ~= "Hitbox" then
				--d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			else
				--d.CanCollide = true
			end
			d.Anchored = true
		end
	end
end

function ServerPlacement.PlaceItem(player, position, itemName, yRotation, localID, filteredModel, ignoreValidation)
	if itemName then
		-- Get item info.
		local plot = PlotUtility.GetPlotFromPlayer(player)
		local item = AssetsDealer.GetItem(itemName)
		local config = require(item.config)
		local type = config.Type

		-- Place the model.
		local model = item.Model:Clone()
		model.Parent = plot.Items
		model.Name = itemName
		model:SetAttribute("ItemType", type)
		local yAngle = math.rad(math.min(yRotation, 360))
		model:PivotTo(CFrame.new(position) * CFrame.Angles(0, yAngle, 0))

		-- Variables
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = { workspace.Nodes, plot.Drops, model, filteredModel }

		-- Validate placement.
		local isPlacementValid = ignoreValidation
			or PlacementUtility.isPlacementValid(plot, model, overlapParams, config)
		if isPlacementValid then
			-- IDs.
			if not localID then
				localID = findAvaiableItemLocalID(plot.Items)
			end
			model:SetAttribute("LocalID", localID)
			model:SetAttribute("ItemName", itemName)
			setModelStreamingMode(model, player)
			ServerPlacement.DisableQueries(model)

			-- Instanciate classes.
			local placementFunctions = {
				Dropper = function()
					ServerDropper.new({
						plot = plot,
						owner = player,
						model = model,
						config = config,
					})
				end,
				Belt = function()
					model.Belt:SetAttribute("Speed", config.BeltSpeed or 1)
					model.Belt:SetAttribute("Slipperiness", config.BeltSlipperiness or 10)
				end,
				Forge = function()
					model.Seller:SetAttribute("SellMultiplier", config.SellMultiplier)
				end,
				Upgrader = function()
					model.Upgrader:SetAttribute("BoostType", config.BoostType or "Additive")
					model.Upgrader:SetAttribute("BoostValue", config.BoostValue or 1)
				end,
				-- Decor = function()
				-- end;
			}
			if placementFunctions[type] then
				task.defer(placementFunctions[type])
			end
			return true, localID
		else
			model:Destroy()
			local str = " position:"
				.. tostring(position)
				.. " yRotation:"
				.. tostring(yRotation)
				.. " itemName:"
				.. itemName
			return false, string.gsub(errors.InvalidPositionAndRotation, "&a", str)
		end
	else
		return false, string.gsub(errors.ItemNameDoesntExist, "&a", itemName)
	end
end

local function checkItemPrimaryPart(item, folder)
	if not item.PrimaryPart then
		local root = item:FindFirstChild("Root")
		if root then
			item.PrimaryPart = root
		else
			error(
				"CRITICAL: "
					.. folder.Name
					.. "'s model doesn't have a primary part, and there is no part named 'Root'."
			)
		end
	end
end

local function generateDefaultEdges(item)
	local root = item.PrimaryPart
	local size = root.Size
	local hX = size.X / 2
	local hZ = size.Z / 2
	local x = Vector3.xAxis
	local z = Vector3.zAxis
	local edgeBias = 0.1 -- So the raycasts of edges at the limits of the plot dont go through
	local bHX = (hX - edgeBias)
	local bHZ = (hZ - edgeBias)
	local positions = {
		-x * bHX + z * bHZ,
		x * bHX - z * bHZ,
		x * bHX + z * bHZ,
		-x * bHX - z * bHZ,
	}
	for _, pos in pairs(positions) do
		local edge = Instance.new("Attachment")
		edge.Name = "Edge"
		edge.Parent = root
		-- edge.Visible = true
		local heightBias = -Vector3.yAxis * size.Y / 2
		local extraBias = Vector3.yAxis * 0.1 -- So it's not exactlly on the plot, which causes the raycasting to go through
		edge.Position = pos + heightBias + extraBias
	end
end

local BELT_TRESHOLD = 0.2
local function setupBelt(belt)
	belt.Size = Vector3.new(belt.Size.X + BELT_TRESHOLD, belt.Size.Y, belt.Size.Z + BELT_TRESHOLD)
end

local function setupItems()
	-- Missing primary part:
	local descendants = ReplicatedStorage.Assets.Items:GetDescendants()
	for _, item in pairs(descendants) do
		if item:IsA("Model") then
			local folder = item.Parent
			if folder:IsA("Folder") then
				-- It's an item:
				checkItemPrimaryPart(item, folder)

				local anyEdge = item.PrimaryPart:FindFirstChild("Edge")
				if not anyEdge then
					generateDefaultEdges(item)
				end

				local belt = item:FindFirstChild("Belt")
				if belt then
					setupBelt(belt)
				end
			end
		end
	end
end

function ServerPlacement.PlaceStarterItems(player)
	local plot = PlotUtility.GetPlotFromPlayer(player)
	if not plot then
		warn("No plot found for player: " .. player.Name)
		return false
	end

	local root = plot:WaitForChild("Root")
	local centerPosition = root.Position + Vector3.new(0, root.Size.Y / 2, 0)


	-- Place OldBelt at center
	local beltPosition = centerPosition + Vector3.new(-2, 0.2, 0) -- Offset to the left
	local beltSuccess, beltLocalID = ServerPlacement.PlaceItem(player, beltPosition, "OldBelt", 270, nil, nil, true)

	if beltSuccess then
		-- Convert to local position and register
		local localBeltPosition = beltPosition - root.Position
		ItemsAccess.RegisterPlacedItem(player, beltLocalID, localBeltPosition, "OldBelt", 270)
	end

	-- Place OldForge next to the belt
	local forgePosition = centerPosition + Vector3.new(2, 0.2, 0) -- Offset to the right
	local forgeSuccess, forgeLocalID = ServerPlacement.PlaceItem(player, forgePosition, "OldForge", 0, nil, nil, true)

	if forgeSuccess then
		-- Convert to local position and register
		local localForgePosition = forgePosition - root.Position
		ItemsAccess.RegisterPlacedItem(player, forgeLocalID, localForgePosition, "OldForge", 0)
	end

	return beltSuccess and forgeSuccess
end

function ServerPlacement.Setup()
	Events.Place.OnServerInvoke = function(player, itemName, position, yRotation)
		local actionTag = " > Events.Place"
		local playerTag = " #" .. player.UserId

		if typeof(position) ~= "Vector3" then
			warn(string.gsub(errors.InvalidArgumentType, "&a", "position") .. playerTag .. actionTag)
			return false
		end
		if typeof(yRotation) ~= "number" then
			warn(string.gsub(errors.InvalidArgumentType, "&a", "yRotation") .. playerTag .. actionTag)
			return false
		end
		if typeof(itemName) ~= "string" then
			warn(string.gsub(errors.InvalidArgumentType, "&a", "itemName") .. playerTag .. actionTag)
			return false
		end

		local storageItem = ItemsAccess.GetStorageItem(player, itemName)
		if not storageItem then
			warn(errors.PlayerDoesntHaveStorageItem .. playerTag .. actionTag)
			return false
		end

		local success, localID = ServerPlacement.PlaceItem(player, position, itemName, yRotation)

		if not success then
			warn("Error from player placement request : ``" .. localID .. "``" .. playerTag .. actionTag)
			return false
		end

		-- Convert absolute position to local position relative to plot root
		local plot = PlotUtility.GetPlotFromPlayer(player)
		local root = plot:WaitForChild("Root")
		local localPosition = position - root.Position
		ItemsAccess.RegisterPlacedItem(player, localID, localPosition, itemName, yRotation)
		ItemsAccess.ConsumeStorageItems(player, itemName, 1)

		-- Log onboarding step
		OnboardingAccess.Complete(player, "FirstItemPlaced")

		return localID
	end
	Events.Move.OnServerInvoke = function(player, localID, position, yRotation)
		local actionTag = " > Events.Move"
		local playerTag = " #" .. player.UserId

		if typeof(position) ~= "Vector3" then
			warn(string.gsub(errors.InvalidArgumentType, "&a", "position") .. playerTag .. actionTag)
			return false
		end
		if typeof(yRotation) ~= "number" then
			warn(string.gsub(errors.InvalidArgumentType, "&a", "yRotation") .. playerTag .. actionTag)
			return false
		end
		if typeof(localID) ~= "number" then
			warn(string.gsub(errors.InvalidArgumentType, "&a", "localID") .. playerTag .. actionTag)
			return false
		end

		local plot = PlotUtility.GetPlotFromPlayer(player)
		local placedModel = PlacementUtility.GetItemFromLocalID(plot.Items, localID)
		local placedItem = ItemsAccess.GetPlacedItem(player, localID)
		if not placedModel then
			warn(
				string.gsub(errors.PlayerDoesntHavePlacedItemToMove, "&a", tostring(localID)) .. playerTag .. actionTag
			)
			return false
		end
		if not placedItem then
			warn(
				string.gsub(errors.PlayerDoesntHavePlacedItemInDatastoreToMove, "&a", tostring(localID))
					.. playerTag
					.. actionTag
			)
			return false
		end
		local placedItemName = placedItem[4]

		-- Move.
		local success, arg1 =
			ServerPlacement.PlaceItem(player, position, placedItemName, yRotation, localID, placedModel)
		if not success then
			warn("Error from player placement request : ``" .. arg1 .. "``" .. playerTag .. actionTag)
			return false
		end

		-- Convert absolute position to local position relative to plot root
		local root = plot:WaitForChild("Root")
		local localPosition = position - root.Position
		ItemsAccess.RegisterPlacedItem(player, localID, localPosition, placedItemName, yRotation)
		placedModel:Destroy()
		--ItemsAccess.ConsumeStorageItems(player,placedItemName,1)
		return true
	end
	Events.Deposit.OnServerInvoke = function(player, localID)
		local actionTag = " > Events.Deposit"
		local playerTag = " #" .. player.UserId

		if typeof(localID) ~= "number" then
			warn(string.gsub(errors.InvalidArgumentType, "&a", "localID") .. playerTag .. actionTag)
			return false
		end

		local plot = PlotUtility.GetPlotFromPlayer(player)
		local placedModel = PlacementUtility.GetItemFromLocalID(plot.Items, localID)
		local placedItem = ItemsAccess.GetPlacedItem(player, localID)
		if not placedModel then
			warn(errors.PlayerDoesntHavePlacedItemToStore .. playerTag .. actionTag)
			return false
		end
		if not placedItem then
			warn(errors.PlayerDoesntHavePlacedItemToStore .. playerTag .. actionTag)
			return false
		end
		local placedItemName = placedItem[4]

		placedModel:Destroy()
		ItemsAccess.RemovePlacedItem(player, localID)
		ItemsAccess.GiveStorageItems(player, placedItemName, 1)
		return true
	end

	setupItems()
end

return ServerPlacement
