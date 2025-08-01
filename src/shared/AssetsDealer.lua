local AssetsDealer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local function xerror(key, arg1, arg2)
	arg1 = tostring(arg1) or "nil"
	arg2 = tostring(arg2) or "nil"
	local errors = {
		invalidRoot = "No Root folder called ``" .. arg1 .. "`` exists.",
		invalidDirectory = "Couldn't find any object at ``" .. arg1 .. "``",
		invalidName = "No asset called ``" .. arg1 .. "`` exists in ``" .. arg2 .. "``",
		missingParameter = "Missing parameter ``" .. arg1 .. "``",
	}
	warn(errors[key])
end

function AssetsDealer.GetAssetFromDirectory(rootFolderName, directory, asClone)
	local rootFolder = Assets:FindFirstChild(rootFolderName)
	if rootFolder then
		local splitDirectory = directory:split("/")
		local current = rootFolder:FindFirstChild(splitDirectory[1])
		if current then
			for i = 2, 100 do
				if splitDirectory[i] then
					current = current:FindFirstChild(splitDirectory[i])
				end
			end
			if not current then
				xerror("invalidDirectory", directory)
			end
			return (asClone and current:Clone()) or current
		end
		xerror("invalidDirectory", directory)
		return nil
	else
		xerror("invalidRoot", rootFolderName)
		return nil
	end
end

function AssetsDealer.GetAssetFromName(rootFolderName, name, asClone)
	local rootFolder = ReplicatedStorage.Assets:FindFirstChild(rootFolderName)
	local asset = nil
	if rootFolder then
		for _, descendant in rootFolder:GetDescendants() do
			if descendant.Name == name then
				asset = descendant
			end
		end
	else
		xerror("invalidRoot", rootFolderName)
	end
	if asset then
		return (asClone and asset:Clone()) or asset
	else
		xerror("invalidName", name, rootFolderName)
	end
	return nil
end

function AssetsDealer.GetItem(name)
	local item = AssetsDealer.GetAssetFromName("Items", name, false)
	if not item then
		warn(`Item not found with name "{name}"`)
		item = AssetsDealer.GetItem("Missing")
	end
	return item
end

function AssetsDealer.GetTile(directory)
	return AssetsDealer.GetAssetFromDirectory("Tiles", directory, true)
end

function AssetsDealer.GetMesh(name)
	if not name then
		error("missingParameter", name)
	end
	return AssetsDealer.GetAssetFromName("Meshes", name, true)
end

function AssetsDealer.GetSound(directory)
	return AssetsDealer.GetAssetFromDirectory("Sounds", directory, false)
end

function AssetsDealer.GetVFX(directory)
	return AssetsDealer.GetAssetFromDirectory("VFX", directory, true)
end

function AssetsDealer.GetParticle(directory)
	local particle = AssetsDealer.GetAssetFromDirectory("Particles", directory, false)
		:FindFirstChildOfClass("Attachment")
		:FindFirstChildOfClass("ParticleEmitter")
		:Clone()
	particle.Rate = 0
	particle.Enabled = false
	return particle
end

function AssetsDealer.GetAnimation(directory)
	return AssetsDealer.GetAssetFromDirectory("Animations", directory, false)
end

function AssetsDealer.GetLootbox(name)
	return AssetsDealer.GetAssetFromName("Lootboxes", name, true)
end

function AssetsDealer.GetTexture(directory)
	local part = AssetsDealer.GetAssetFromDirectory("Textures", directory, false)
	return (part and part.Decal and part.Decal.Texture) or nil
end

function AssetsDealer.GetUi(directory)
	local part = AssetsDealer.GetAssetFromDirectory("Ui", directory, false)
	local ui = part:FindFirstChildOfClass("Attachment"):FindFirstChildOfClass("BillboardGui"):Clone()

	return ui
end

return AssetsDealer
