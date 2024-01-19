local ItemUtility = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local AssetsDealer = require(Shared.AssetsDealer)
local ItemInfo = require(Shared.Items.ItemInfo)

function ItemUtility.GetItemFromID(ID)
    ID = tonumber(ID)
    for name,item in pairs(ItemInfo) do
        if item.ID == ID then
            return name,item
        end
    end
    return nil,nil
end

function ItemUtility.GetItemConfig(name)
    local item = AssetsDealer.GetItem(ItemInfo[name].Directory)
    return require(item.config)
end

return ItemUtility