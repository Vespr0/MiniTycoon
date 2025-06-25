local StocksSimulator = {}

local RunService = game:GetService("RunService")

local minerals = {
	Coal = { baseSellPrice = 10, sellPrice = 10, sold = 1 },
	Iron = { baseSellPrice = 50, sellPrice = 50, sold = 1 },
	Diamond = { baseSellPrice = 200, sellPrice = 200, sold = 1 }
}

local function getDemandRatios()
	local averageSold = 0
	local ratios = {}
	for mineral, data in minerals do
		averageSold += data.sold
	end
	
	for mineral, data in minerals do
		local ratio = data.sold > 0 and data.sold / averageSold or 1/averageSold
		ratios[mineral] = ratio
	end
	return ratios
end

local function updatePrices(mineral,demandRatio)
	local basePrice = minerals[mineral].baseSellPrice
	
	print(demandRatio)
	minerals[mineral].sellPrice = (basePrice / demandRatio) ^ 0.9
end

local function sellMineral(mineral, quantity)
	minerals[mineral].sold = minerals[mineral].sold + quantity
	print(mineral .. " sold. Total sold: " .. minerals[mineral].sold)
end

local function printMarket()
	print("^^^^^^^^^^^^^^^^^^^^^^^^^^")
	print("Current Market Sell Prices:")
	for mineral, data in pairs(minerals) do
		print(mineral .. ": $" .. string.format("%.2f", data.sellPrice))
	end
	print("vvvvvvvvvvvvvvvvvvvvvvvvvv")
end

local function updateMarket()
	local demandRatios = getDemandRatios()
	for mineral, data in minerals do
		updatePrices(mineral,demandRatios[mineral])
	end
	printMarket()
end

function StocksSimulator.Setup()
	---- Update market prices
	--printMarket()
	
	--updateMarket()
	---- Assuming you want to update the market every 60 seconds
	--local updateInterval = 10
	--local timeElapsed = 0
	
	---- Simulate selling minerals
	--sellMineral("Coal", 1000)
	--sellMineral("Iron", 1000)
	--sellMineral("Diamond", 5)
	
	--RunService.Heartbeat:Connect(function(deltaTime)
	--	timeElapsed = timeElapsed + deltaTime

	--	if timeElapsed >= updateInterval then
	--		updateMarket()
	--		printMarket()
	--	timeElapsed = 0
	--	end
	--end)
end

return StocksSimulator
