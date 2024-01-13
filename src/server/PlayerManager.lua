local PlayerManager = {}

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage.Events

-- Setup collision groups.
PhysicsService:RegisterCollisionGroup("Players")
PhysicsService:RegisterCollisionGroup("Drops")
PhysicsService:CollisionGroupSetCollidable("Players","Drops",false)

function PlayerManager.Setup()
    -- Setup collision groups for the player character.
    local function setupCharacter(character: Model)
        for _,desc in pairs(character:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.CollisionGroup = "Players"
            end
        end
    end
    local function setupPlayer(player: Player) 
        if player.Character then
            setupCharacter(player.Character)
        end  
        player.CharacterAdded:Connect(function(character)
            setupCharacter(character)
        end)
    end
    for _,player in pairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
    -- When a player joins.
    Players.PlayerAdded:Connect(function(player)
        setupPlayer(player)
    end)
    -- When a player leaves.
    Players.PlayerRemoving:Connect(function(player)
        
    end)
    -- Client loading.
    Events.ClientLoaded.OnServerEvent:Connect(function(player)
        player:SetAttribute("ClientLoaded",true)
    end)
end

return PlayerManager