local ItemUtility = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

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

return ItemUtility