local DataUtility = {}

-- Constants --
local DATA_TYPES = {
    Full = 1;
    Storage = 2;
    Cash = 3;
    -- Level = 4;
    -- Exp = 5;
    PlacedItem = 6;
    Leveling = 7;
    FirstPlayed = 8;
    LastPlayed = 9;
    TimePlayed = 10;
    OffersInfo = 11;
    SingleOffer = 12;
}
local DATA_KEYS = {
    "Cash";"Level";"Exp"
}
local DATA_FOLDERS = {
    "Storage";
}

--[[

Data scopes:

2023:

25 Sep - 25 Jun ["Player#T00"];

2024

25 Jun - ?? ?? ["Player#0"];

--]]

local DATA_SCOPES = {
    Player = "Player#0";
}

function DataUtility.GetTypeFromId(id)
    for typeName,dataId in DATA_TYPES do
        if dataId == id then
            return typeName
        end
    end
    return nil
end

function DataUtility.GetTypeId(name)
    return DATA_TYPES[name]
end

function DataUtility.GetDataScope(name)
    return DATA_SCOPES[name]
end
--[[
function DataUtility.CreateDataFolder()
    local dataFolder = Instance.new("Folder")
    -- Storage folder.
    local storageFolder = Instance.new("Folder")
    storageFolder.Parent = dataFolder
    storageFolder.Name = "Storage"
    -- Cash value.
    for _,key in DATA_KEYS do
        local value = Instance.new("IntValue")
        value.Parent = dataFolder
        value.Name = key
    end
    return dataFolder
end

function DataUtility.ConvertDataFolderToTable(dataFolder)
    local table = {}

    local function recursive(folder,table)
        for _,child in pairs(folder:GetChildren()) do
            local key = child.Name
            if tostring(tonumber(key)) == key then
                key = tonumber(key)
            end
            if child:IsA("Folder") then
                table[key] = {}
                recursive(child,table[key])
            else
                table[key] = child.Value
            end
        end
    end
    recursive(dataFolder,table)

    warn(table)

    return table
end]]

return DataUtility