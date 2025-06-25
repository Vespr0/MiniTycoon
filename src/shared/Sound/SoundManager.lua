local SoundManager = {}

local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local AssetsDealer = require(Shared.AssetsDealer)

function SoundManager.PlaySound(directory,arg2,pitch)
	local Sound = AssetsDealer.GetSound(directory):Clone()
	task.spawn(function()
		local SoundPart
		
		if arg2 then
			if typeof(arg2) == "Vector3" then
				SoundPart = Instance.new("Part",workspace.Nodes.Sounds)
				SoundPart.Anchored = true
				SoundPart.Transparency = 1
				SoundPart.CanQuery = false
				SoundPart.CanCollide = false
				SoundPart.Size = Vector3.new(.5,.5,.5)
				SoundPart.Position = arg2	
			else
				SoundPart = arg2
			end				
		end
		
		local RNG = Random.new()
		if pitch ~= -1 then
			if pitch then
				Sound.PlaybackSpeed = pitch 	
			else
				Sound.PlaybackSpeed = Sound.PlaybackSpeed + RNG:NextInteger(-2,2)/10 			
			end
		end
		--warn(Sound.PlaybackSpeed)
		
		Sound.Parent = arg2 and SoundPart or workspace.Nodes.Sounds		
		Sound:Play()
		wait(Sound.TimeLength-.1)
		local Fading = TweenService:Create(Sound,TweenInfo.new(.1,Enum.EasingStyle.Sine),{Volume = 0})
		Fading:Play()
		wait(.1)
		if arg2 then
			if typeof(arg2) == "Vector3" then
				SoundPart:Destroy()	
			else
				Sound:Destroy()	
			end
		end	
	end)
	return Sound
end

return SoundManager
