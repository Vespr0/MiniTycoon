local AssetsDealer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local function error(key,arg1,arg2)
	arg1 = arg1 or "nil"
	arg2 = arg2 or "nil"
	local errors = {
		invalidRoot = "No Root folder called ``"..arg1.."`` exists.";
		invalidDirectory = "Couldn't find any object at ``"..arg1.."``";
		invalidName = "No asset called ``"..arg1.."`` exists in ``"..arg2.."``";
		missingParameter = "Missing parameter ``"..arg1.."``";
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
		return nil
	else
		error("invalidRoot",rootFolderName)
		return nil
	end
end

function AssetsDealer.GetAssetFromName(rootFolderName,name,asClone)
	local rootFolder = ReplicatedStorage.Assets:FindFirstChild(rootFolderName)
	local asset = nil
	if rootFolder then
		for _,descendant in pairs(rootFolder:GetDescendants()) do
			if descendant.Name == name then
				asset = descendant
			end
		end
	else
		error("invalidRoot",rootFolderName)
	end
	if asset then
		return (asClone and asset:Clone()) or asset
	else
		error("invalidName",name,rootFolderName)
	end
	return nil
end


function AssetsDealer.GetItem(directory)
	return AssetsDealer.GetAssetFromDirectory("Items",directory,false)
end

function AssetsDealer.GetTile(directory)
	return AssetsDealer.GetAssetFromDirectory("Tiles",directory,true)
end

function AssetsDealer.GetMesh(name)
	if not name then
		error("missingParameter",name)
	end
	return AssetsDealer.GetAssetFromName("Meshes",name,true)
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