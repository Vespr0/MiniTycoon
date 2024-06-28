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

	FX.Tween = function(params)
		local Tween = TweenService:Create(params.Instance,TweenInfo.new(params.Time or 1,params.EasingStyle or Enum.EasingStyle.Linear),params.Goals)
		Tween:Play()
	end
	
	FX.Poof = function(params)
		local position = params["attachment"].WorldPosition
        -- Let's save resources. If the position is too far away we can ignore this effect.
		if getDistanceFromCamera(position) > 500 then
			return
		end
		local particle = AssetsDealer.GetParticle(params.particle or "Misc/Pop")
		particle.Parent = params.attachment
		particle.Enabled = true
		particle.LockedToPart = true
		particle:Emit(params.intensity or 4)
		Debris:AddItem(particle,.5)
		SoundManager.PlaySound(params.sound or "Misc/Pop",position)
	end

	FX.Smelt = function(params)
		task.spawn(function()
			local instance = params.instance
			local size = params.size
			local pitch = 1.3 - size.Magnitude/2
			SoundManager.PlaySound("Misc/Smelt",instance.Position, math.clamp(pitch, 0.6, 1.3))

			TweenService:Create(instance,TweenInfo.new(5/2,Enum.EasingStyle.Sine),{
				Color = params.color,
				Transparency = 1,
			}):Play()
			
			task.wait(1/2)

			local pos = instance.Position
			TweenService:Create(instance,TweenInfo.new(2,Enum.EasingStyle.Sine),{
				Position = pos - Vector3.yAxis*math.max(size.X,size.Y,size.Z),
			}):Play()
		end)
	end

	FX.Fade = function(params)
		-- Let's save resources. If the position is too far away we can ignore this effect.
		if getDistanceFromCamera(params["Instance"].Position) > 1000 then
			return
		end
		FX.Tween({
			Instance = params.Instance,
			Time = params.Time or 2,
			EasingStyle = Enum.EasingStyle.Sine,
			Goals = {Transparency = 1}
		})
	end

	Events.FX.OnClientEvent:Connect(function(name,params)
		FX[name](params)
	end)
end

return FX
