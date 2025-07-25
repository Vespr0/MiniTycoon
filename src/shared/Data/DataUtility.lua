local DataUtility = {}

local RunService = game:GetService("RunService")

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

local PLAYER_DATA_SCOPE = (RunService:IsStudio() and "Studio#1" or "Dev#3")
local DATA_SCOPES = {
    Player = PLAYER_DATA_SCOPE;
}

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