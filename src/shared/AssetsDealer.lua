local AssetsDealer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local function error(key,arg1)
	local errors = {
		invalidRoot = "No Root folder called ``"..arg1.."`` exists.";
		invalidDirectory = "Couldn't find any object at ``"..arg1.."``";
	}
	return errors[key]
end

function AssetsDealer.GetAssetFromDirectory(rootFolderName,directory,asClone)
	local rootFolder = Assets:FindFirstChild(rootFolderName)
	if rootFolder then
		local splitDirectory = directory:split('/')
		local current = rootFolder:FindFirstChild(splitDirectory[1])
		if current then
			for i = 2,100 do
				if splitDirectory[i] then
					current = current:FindFirstChild(splitDirectory[i])
				end
			end
			if not current then
				error("invalidDirectory",directory)
			end
			return (asClone and current:Clone()) or current
		end
		error("invalidDirectory",directory)
	else
		error("invalidRoot",rootFolderName)
	end
end

function AssetsDealer.GetItem(directory)
	return AssetsDealer.GetAssetFromDirectory("Items",directory,false)
end

function AssetsDealer.GetTile(directory)
	return AssetsDealer.GetAssetFromDirectory("Tiles",directory,true)
end

function AssetsDealer.GetMesh(directory)
	return AssetsDealer.GetAssetFromDirectory("Meshes",directory,true)
end

function AssetsDealer.GetSound(directory)
	return AssetsDealer.GetAssetFromDirectory("Sounds",directory,false)
end

function AssetsDealer.GetVFX(directory)
	return AssetsDealer.GetAssetFromDirectory("VFX",directory,true)
end

function AssetsDealer.GetParticle(directory)
	local particle = AssetsDealer.GetAssetFromDirectory("Particles",directory,false):FindFirstChildOfClass("Attachment"):FindFirstChildOfClass("ParticleEmitter"):Clone()
	particle.Rate = 0
	particle.Enabled = false
	return particle
end

function AssetsDealer.GetAnimation(directory)
	return AssetsDealer.GetAssetFromDirectory("Animations",directory,false)
end

function AssetsDealer.GetTexture(directory)
	local part = AssetsDealer.GetAssetFromDirectory("Textures",directory,false)
	return (part and part.Decal and part.Decal.Texture) or nil
end

return AssetsDealer