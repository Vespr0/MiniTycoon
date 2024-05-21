local FX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Events = ReplicatedStorage.Events

local AssetsDealer = require(Shared.AssetsDealer)
local SoundManager = require(Shared.Sound.SoundManager)

local function getDistanceFromCamera(pos)
    local Camera = workspace.Camera
	return (pos-Camera.CFrame.Position).Magnitude
end

function FX.Setup()

	FX.Poof = function(params)
		local position = params["attachment"].WorldPosition
        -- Let's save resources. If the position is too far away we can ignore this effect.
		if getDistanceFromCamera(position) > 500 then
			return
		end
		local particle = AssetsDealer.GetParticle(params["particle"] or "Misc/Pop")
		particle.Parent = params["attachment"]
		particle.Enabled = true
		particle.LockedToPart = true
		particle:Emit(params["Intensity"] or 4)
		Debris:AddItem(particle,.5)
		SoundManager.PlaySound(params["sound"] or "Misc/Pop",position)
	end
	
	FX.Tween = function(params)
		local Tween = TweenService:Create(params["Instance"],TweenInfo.new(params["Time"] or 1),params["Goals"])
		Tween:Play()
	end
	
	--[[FX.FadeCorpse = function(params)
		-- Let's save resources. If the position is too far away we can ignore this effect.
		if not params["Corpse"] or not params["Corpse"].PrimaryPart then
			return
		end
		if getDistanceFromCamera(params["Corpse"].PrimaryPart.Position) > 1000 then
			return
		end
		for _,part in pairs(params["Corpse"]:GetDescendants()) do
			if part:IsA("BasePart") then
				FX.Tween({["Instance"] = part,["Goals"] = {Transparency = 1}})
			end
		end
	end]]
	
	FX.FadeDebris = function(params)
		-- Let's save resources. If the position is too far away we can ignore this effect.
		if getDistanceFromCamera(params["Instance"].Position) > 1000 then
			return
		end
		FX.Tween({["Instance"] = params["Instance"],["Time"] = 3,["Goals"] = {Transparency = 1,Size = Vector3.new(0,0,0)}})
	end
	
	Events.FX.OnClientEvent:Connect(function(name,params)
		FX[name](params)
	end)
end

return FX
