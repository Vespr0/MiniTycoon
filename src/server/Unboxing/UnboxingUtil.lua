local UnboxingUtil = {}

local function ConvertValuesToWeights(WeightsFolder)
	local Weights = {}
	for _,Item in pairs(WeightsFolder:GetChildren()) do
		for i = 1,Item.Value do
			table.insert(Weights,Item.Name)			
		end
	end
	return Weights
end

local function CalculateWeightsPercentages(WeightsFolder)
	for _,Item in pairs(WeightsFolder:GetChildren()) do
		local ItemWeight = Item.Value
		local ComparedWeight = 0

		for _,ComparedItem in pairs(WeightsFolder:GetChildren()) do
			ComparedWeight += ComparedItem.Value
		end
		print(Item.Name.. " - ".. (ItemWeight/ComparedWeight)*100 .."%")
	end
end

local function ChooseRandomItemFromWeights(WeightsFolder)
	local Weights = ConvertValuesToWeights(WeightsFolder)
	return Weights[math.random(1,#Weights)]
end

return UnboxingUtil
