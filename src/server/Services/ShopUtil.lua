local ShopUtil = {}

-- Example: Validate if an item exists in the shop pool (to be expanded as needed)
function ShopUtil.IsValidShopItem(itemName, itemPool)
	for _, item in ipairs(itemPool) do
		if item.Name == itemName then
			return true
		end
	end
	return false
end

-- Example: Get item data from pool by name
function ShopUtil.GetItemData(itemName, itemPool)
	for _, item in ipairs(itemPool) do
		if item.Name == itemName then
			return item
		end
	end
	return nil
end

-- Example: Calculate price (expand as needed for discounts, etc.)
function ShopUtil.GetItemPrice(itemData)
	return itemData and itemData.Price or nil
end

return ShopUtil
