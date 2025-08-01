local PlayerManager = {}
local Data = script.Parent.Parent.Data
local BadgeManager = require(Data.BadgeManager)
local OnboardingAccess = require(Data.DataAccessModules.OnboardingAccess)

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
        BadgeManager.Award(player, "Welcome")
        OnboardingAccess.Complete(player, "FirstPlayed")
    end)
    -- When a player leaves.
    Players.PlayerRemoving:Connect(function(player)
        
    end)
    -- Client loading.
    Events.ClientLoaded.OnServerInvoke = function(player)
        player:SetAttribute("ClientLoaded",true)
        return true
    end
end

return PlayerManager