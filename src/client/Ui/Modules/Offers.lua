local Offers = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages
local Events = ReplicatedStorage.Events

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local Time = require(Shared.Utility.Time)
local ViewportUtil = require(script.Parent.Util.Viewport)
local Insight = require(script.Parent.InsightFrame)
local PopupUi = require(script.Parent.Popup)

-- Ui Elements
local MainFrame = Ui.ShopGui:WaitForChild("MainFrame")
local OffersFrame = MainFrame:WaitForChild("OffersFrame")
local OffersContainer = OffersFrame:WaitForChild("OffersContainer")
local ItemTemplate = OffersContainer:WaitForChild("ItemTemplate")
local ViewportGradient = OffersFrame:WaitForChild("ViewportGradient")
ViewportGradient.Parent = script
ItemTemplate.Parent = script
local Timer = OffersFrame:WaitForChild("Timer")

-- Modules --
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientPlacement = require(script.Parent.Parent.Parent.Items.ClientPlacement)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)
local ItemUtility = require(Shared.Items.ItemUtility)
local DataUtility = require(Shared.Data.DataUtility)
local CashUtility = require(Shared.Utility.CashUtility)
local ShopInfo = require(ReplicatedStorage.Shared.Services.ShopInfo)
local Tween = require(script.Parent.Util.Tween)
local Colors = require(script.Parent.Util.Colors)
local Trove = require(Packages.trove)

-- Constants --

-- Variables --
local trove = require(Packages.trove).new()
local currentExpiration
local currentOffers
local currentViewports = {}

-- Local Functions
function get()
	local data = Events.Offers:InvokeServer("Get")

	currentExpiration = data.expiration
	currentOffers = data.offers
end

-- local currentInsightTrove = nil -- Moved to InsightFrame.lua

-- local function canAfford(price) -- Moved to InsightFrame.lua
-- 	return ClientPlayerData.Data.Cash >= price
-- end

local function buyOffer(offerID, price, itemName)
	Ui.PlaySound("Purchase")

	local success, error = Events.Offers:InvokeServer("Buy", { offerID = offerID })
	if not success then
		warn(error)
		return
	end

	ClientPlayerData.Read({
		type = "SingleOffer",
		arg1 = offerID,
		arg2 = {
			ItemName = itemName,
			Price = price,
			Bought = true,
		},
	})

	OffersContainer[offerID].Sold.Visible = true
    -- Hide sale
    OffersContainer[offerID].Sale.Visible = false

	Insight.Close() -- Use the new Close function

	local itemConfig = ItemUtility.GetItemConfig(itemName)
	local message = PopupUi.GenerateItemPurchaseMessage(itemName, price, itemConfig)
	PopupUi.Enqueue(itemName, message, 1)
end

local function checkExpiration()
	local diff = os.difftime(currentExpiration, workspace:GetServerTimeNow())
	return diff <= 0, diff
end

local function updateContainer()
	if checkExpiration() then
		return
	end -- Shoudln't be expired.

	for _, offer in pairs(OffersContainer:GetChildren()) do
		if offer:IsA("TextButton") then
			offer:Destroy()
		end
	end
	currentViewports = {} -- TODO: is this a memory leak? (Yes, if the viewports aren't destroyed when the offers are removed)

	if not currentOffers or not next(currentOffers) then
		return
	end

	for offerID, offer in pairs(currentOffers) do
		local itemName = offer.ItemName
		local price = offer.Price
		local bought = offer.Bought

		local config = ItemUtility.GetItemConfig(itemName)

		if not itemName then
			warn("Item with ID " .. itemName .. " does not exist, can't show offer.")
			continue
		end

		local item = ItemTemplate:Clone()
		item.Name = offerID
		item.Parent = OffersContainer

		-- ItemName
		local itemNameLabel = item:WaitForChild("ItemName")
		itemNameLabel.Text = config.DisplayName or itemName

		-- Bought
		item.Sold.Visible = bought

		-- Price
		item:WaitForChild("Price").Text = CashUtility.Format(price, {
			fullNumber = false,
			decimals = 0,
		})

		-- Sale discount
		local saleLabel = item:FindFirstChild("Sale")
		if saleLabel then
			local discountPercent, hasDiscount = ShopInfo.CalculateDiscount(itemName, price)
			if hasDiscount then
				saleLabel.Text = discountPercent .. "% OFF"
				saleLabel.Visible = true
			else
				saleLabel.Visible = false
			end
		end

		local viewport = ViewportUtil.CreateItemViewport(itemName)
		viewport.Parent = item

		table.insert(currentViewports, viewport)

		local gradient = ViewportGradient:Clone()
		gradient.Parent = viewport

		local rarity = config.Rarity or "Common"
		item.MouseButton1Click:Connect(function()
			if item.Sold.Visible then
				Ui.PlaySound("Error")
				return
			end
			
			-- Call the new InsightFrame.Open function
			Insight.Open(config, itemName, price, nil, rarity, function()
				buyOffer(offerID, price, itemName) -- Pass the Offers-specific buy logic as a callback
			end)
		end)
	end
end

function Offers.Reload()
	get()
	local expired = checkExpiration()
	if not expired then
		updateContainer()
	end
end

local function spin()
	local preview = Insight.Preview
	if not preview then
		return
	end

	local model = preview:FindFirstChildWhichIsA("Model")
	if model then
		model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(0.3), 0))
	end
end

local function update()
	local expired, diff = checkExpiration()
	MainFrame:WaitForChild("Shadow").Visible = expired
	Timer.Text = "Offers reset in: " .. Time.GetFullTimeString(diff)

	-- Spin
	spin()
end

-- Module Functions
function Offers.Open()
	OffersFrame.Visible = true
	-- Optionally close Insight when opening OffersFrame
	Insight.Close()
end

function Offers.Close()
	OffersFrame.Visible = false
	-- Optionally close Insight when closing OffersFrame
	Insight.Close()
end

function Offers.Setup()
	Offers.Reload()
	Insight.Close() -- Use the new Close function
	local paused = false
	RunService.RenderStepped:Connect(function()
		if checkExpiration() then
			if paused then
				return
			end
			paused = true
			Offers.Reload()
			paused = false
		end
		update()
	end)
end

return Offers
