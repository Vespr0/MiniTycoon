local ItemUtility = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local AssetsDealer = require(Shared.AssetsDealer)
local ItemInfo = require(Shared.Items.ItemInfo)

-- function ItemUtility.GetItemFromID(ID)
--     ID = tonumber(ID)
--     for name,id in pairs(ItemInfo.IDs) do
--         id = tonumber(id)
--         if id == ID then
--             return name
--         end
--     end
--     return nil,nil
-- end

function ItemUtility.GetItemConfig(name)
	local item = AssetsDealer.GetItem(name)
    return require(item.config)
end

return ItemUtility