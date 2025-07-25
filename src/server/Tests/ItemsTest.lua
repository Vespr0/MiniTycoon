local ItemsTest = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Modules
local AssetsDealer = require(Shared.AssetsDealer)
local ItemUtility = require(Shared.Items.ItemUtility)
local ProductsInfo = require(Shared.Items.ProductsInfo)
local GameConfig = require(Shared.GameConfig)

ItemsTest.Enabled = true

-- Required fields for different item types (Type is always required and checked separately)
local REQUIRED_FIELDS = {
	Dropper = {
		"DisplayName",
		"Description",
		"DropDelay",
		"DropPropieties",
		"ProductType",
		"ProductQuantity",
		"CanPlaceOnWater",
		"CanPlaceOnGround",
	},
	Belt = {
		"DisplayName",
		"BeltSpeed",
		"CanPlaceOnGround",
		"CanPlaceOnWater",
	},
	Upgrader = {
		"DisplayName",
		"BoostType",
		"BoostValue",
	},
	Forge = {
		"DisplayName",
	},
	Decor = {
		"DisplayName",
	},
}

-- Expected field types
local FIELD_TYPES = {
	Type = "string",
	DisplayName = "string",
	Description = "string",
	DropDelay = "number",
	DropPropieties = "table",
	ProductType = "string",
	ProductQuantity = "number",
	CanPlaceOnWater = "boolean",
	CanPlaceOnGround = "boolean",
	BeltSpeed = "number",
	BoostType = "string",
	BoostValue = "number",
}

-- Valid values for specific fields
local VALID_VALUES = {
	Type = GameConfig.ItemTypes,
	BoostType = { "Additive", "Multiplicative" },
}

local function validateField(itemName, config, fieldName, expectedType)
	local value = config[fieldName]

	if value == nil then
		warn(`❌ {itemName}: Missing required field '{fieldName}'`)
		return false
	end

	if expectedType and type(value) ~= expectedType then
		warn(`❌ {itemName}: Field '{fieldName}' should be {expectedType}, got {type(value)}`)
		return false
	end

	-- Check valid values for specific fields
	if VALID_VALUES[fieldName] then
		local validValues = VALID_VALUES[fieldName]
		local isValid = false
		for _, validValue in ipairs(validValues) do
			if value == validValue then
				isValid = true
				break
			end
		end
		if not isValid then
			warn(
				`❌ {itemName}: Field '{fieldName}' has invalid value '{value}'. Valid values: {table.concat(
					validValues,
					", "
				)}`
			)
			return false
		end
	end

	return true
end

local function validateDropPropieties(itemName, dropPropieties)
	if type(dropPropieties) ~= "table" then
		warn(`❌ {itemName}: DropPropieties should be a table`)
		return false
	end

	local requiredDropFields = { "name", "value", "size", "color", "mesh" }
	local isValid = true

	for _, field in ipairs(requiredDropFields) do
		if dropPropieties[field] == nil then
			warn(`❌ {itemName}: DropPropieties missing required field '{field}'`)
			isValid = false
		end
	end

	-- Validate specific types in DropPropieties
	if dropPropieties.value and type(dropPropieties.value) ~= "number" then
		warn(`❌ {itemName}: DropPropieties.value should be number`)
		isValid = false
	end

	if dropPropieties.size and type(dropPropieties.size) ~= "number" then
		warn(`❌ {itemName}: DropPropieties.size should be number`)
		isValid = false
	end

	if dropPropieties.color and typeof(dropPropieties.color) ~= "Color3" then
		warn(`❌ {itemName}: DropPropieties.color should be Color3`)
		isValid = false
	end

	if dropPropieties.mesh and type(dropPropieties.mesh) ~= "string" then
		warn(`❌ {itemName}: DropPropieties.mesh should be string`)
		isValid = false
	end

	return isValid
end

local function validateProductType(itemName, config)
	if not config.ProductType then
		return true
	end

	if not ProductsInfo.Products[config.ProductType] then
		warn(`❌ {itemName}: ProductType '{config.ProductType}' not found in ProductsInfo`)
		return false
	end

	return true
end

local function validateNumericRanges(itemName, config)
	local isValid = true

	-- Validate positive numbers
	local positiveFields = { "DropDelay", "ProductQuantity", "BeltSpeed", "BoostValue" }
	for _, field in ipairs(positiveFields) do
		if config[field] and config[field] <= 0 then
			warn(`❌ {itemName}: {field} should be positive, got {config[field]}`)
			isValid = false
		end
	end

	-- Validate reasonable ranges
	if config.DropDelay and config.DropDelay > 300 then -- 5 minutes max seems reasonable
		warn(`❌ {itemName}: DropDelay seems too high ({config.DropDelay}s), consider if this is intentional`)
	end

	if config.BeltSpeed and config.BeltSpeed > 100 then
		warn(`❌ {itemName}: BeltSpeed seems very high ({config.BeltSpeed}), consider if this is intentional`)
	end

	return isValid
end

local function validatePlacementLogic(itemName, config)
	if config.CanPlaceOnWater == nil or config.CanPlaceOnGround == nil then
		return true -- Not all items need placement logic
	end

	if not config.CanPlaceOnWater and not config.CanPlaceOnGround then
		warn(`❌ {itemName}: Item cannot be placed anywhere (both CanPlaceOnWater and CanPlaceOnGround are false)`)
		return false
	end

	return true
end

local function validateItemConfig(itemName, config)
	local isValid = true

	-- First validate Type field exists and is valid
	if not validateField(itemName, config, "Type", "string") then
		return false
	end

	local itemType = config.Type
	print(`Validating {itemName} (Type: {itemType})`)

	-- Get required fields for this item type
	local requiredFields = REQUIRED_FIELDS[itemType]
	if not requiredFields then
		warn(`❌ {itemName}: Unknown item type '{itemType}'`)
		return false
	end

	-- Validate required fields
	for _, fieldName in ipairs(requiredFields) do
		local expectedType = FIELD_TYPES[fieldName]
		if not validateField(itemName, config, fieldName, expectedType) then
			isValid = false
		end
	end

	-- Special validations for droppers
	if itemType == "Dropper" then
		if config.DropPropieties and not validateDropPropieties(itemName, config.DropPropieties) then
			isValid = false
		end

		if not validateProductType(itemName, config) then
			isValid = false
		end
	end

	-- Validate numeric ranges
	if not validateNumericRanges(itemName, config) then
		isValid = false
	end

	-- Validate placement logic
	if not validatePlacementLogic(itemName, config) then
		isValid = false
	end

	if isValid then
		print(`✅ {itemName}: Valid configuration`)
	end

	return isValid
end

function ItemsTest.Run()
	local itemsFolder = ReplicatedStorage.Assets:FindFirstChild("Items")
	if not itemsFolder then
		warn("❌ No Items folder found in Assets")
		return
	end

	local totalItems = 0
	local validItems = 0
	local errors = {}
	local itemsByType = {}

	-- Test each item in the Assets/Items folder
	for _, item in ipairs(itemsFolder:GetChildren()) do
		if item:IsA("Folder") then
			-- Check if config exists (only folders with configs are considered items)
			local configScript = item:FindFirstChild("config")
			if not configScript then
				-- Skip organizational folders that don't have configs
				continue
			end

			totalItems += 1

			-- Try to require the config
			local success, config = pcall(function()
				return require(configScript)
			end)

			if not success then
				warn(`❌ {item.Name}: Failed to require config - {config}`)
				table.insert(errors, `{item.Name}: Config require failed`)
				continue
			end

			-- Track items by type
			local itemType = config.Type or "Unknown"
			if not itemsByType[itemType] then
				itemsByType[itemType] = 0
			end
			itemsByType[itemType] += 1

			-- Validate the config
			if validateItemConfig(item.Name, config) then
				validItems += 1
			else
				table.insert(errors, `{item.Name}: Invalid configuration`)
			end
		end
	end

	-- Summary
	print("\nTest Results:")
	print(`Total Items: {totalItems}`)
	print(`Valid Items: {validItems}`)
	print(`Invalid Items: {totalItems - validItems}`)

	-- Items by type breakdown
	print("\nItems by Type:")
	for itemType, count in pairs(itemsByType) do
		print(`  {itemType}: {count}`)
	end

	if #errors > 0 then
		print("\n❌ Errors found:")
		for _, error in ipairs(errors) do
			print(`  • {error}`)
		end
	else
		print("\n✅ All item configurations are valid!")
	end

	-- Test ProductsInfo consistency
	print("\nValidating ProductsInfo...")
	local productCount = 0
	for productName, productData in pairs(ProductsInfo.Products) do
		productCount += 1

		if not productData.BaseSellValue then
			warn(`❌ Product '{productName}': Missing BaseSellValue`)
		elseif type(productData.BaseSellValue) ~= "number" then
			warn(`❌ Product '{productName}': BaseSellValue should be number`)
		elseif productData.BaseSellValue <= 0 then
			warn(`❌ Product '{productName}': BaseSellValue should be positive`)
		else
			print(`✅ Product '{productName}': Valid (BaseSellValue: {productData.BaseSellValue})`)
		end
	end

	print(`\nFound {productCount} products in ProductsInfo`)
	print("✅ Items test completed!")
end

return ItemsTest
