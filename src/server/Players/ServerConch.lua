local ServerConch = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local conch = require(ReplicatedStorage.Packages.conch)

function ServerConch.SetupPlayer(player: Player)
    local user = conch.get_user(player)

    if table.find(GameConfig.AdminUserIds, player.UserId) then
        conch.give_roles(user, "super-user")
    end
end

function ServerConch.SetupPermissions()
    for _, player in Players:GetPlayers() do
        ServerConch.SetupPlayer(player)
    end
    Players.PlayerAdded:Connect(function(player)
        ServerConch.SetupPlayer(player)
    end)
end

function ServerConch.RegisterAllCommands()
    local Utility = {}
    Utility.Conch = conch

    for _, commandModule in script.Parent.Commands:GetChildren() do
        local module = require(commandModule)
        
        if module.Register then
            module.Register(Utility)
        end
    end
end

function ServerConch.Setup()
    conch.initiate_default_lifecycle()
    conch.register_default_commands()
    
    ServerConch.SetupPermissions()
    ServerConch.RegisterAllCommands()
end

return ServerConch