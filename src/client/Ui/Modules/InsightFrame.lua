local Insight = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Local Player
local Player = Players.LocalPlayer

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local ViewportUtil = require(script.Parent.Util.Viewport) 
local ItemInfo = require(game.ReplicatedStorage.Shared.Items.ItemInfo)

-- Modules
local Trove = require(game.ReplicatedStorage.Packages.trove) 
local CashUtility = require(game.ReplicatedStorage.Shared.Utility.CashUtility)
local ButtonUtility = require(script.Parent.Util.ButtonUtility)
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData) 
local TipsUtility = require(script.Parent.Util.TipsUtility)

-- Ui Elements
local MainFrame = Ui.ShopGui:WaitForChild("MainFrame") 
local InsightFrame = MainFrame:WaitForChild("InsightFrame")
local Preview = InsightFrame:WaitForChild("Preview")
local Button = InsightFrame:WaitForChild("Buy")
local TipsFrame = Preview:WaitForChild("Tips")

Insight.InsightFrame = InsightFrame
Insight.Preview = Preview
Insight.Button = Button

-- Variables
local currentInsightTrove = nil


local function canAfford(price, levelRequirement)
	local hasCash = ClientPlayerData.Data.Cash >= price
	if levelRequirement then
		return hasCash and (ClientPlayerData.Data.Level >= levelRequirement)
	end
	return hasCash
end

function Insight.Open(itemConfig, itemName, price, levelRequirement, rarity, buyCallback)
	-- Destroy previous trove if it exists
	if currentInsightTrove then currentInsightTrove:Destroy() end
	currentInsightTrove = Trove.new()

	-- Set UI Text
	InsightFrame.Title.Text = itemConfig.DisplayName
	InsightFrame.Description.Text = itemConfig.Description or '<font transparency="0.5"> This item has no description. </font>'

	-- Rarity info
	local rarityInfo = ItemInfo.Rarities[rarity or "Common"]
	InsightFrame.Rarity.Text = string.upper(itemConfig.Rarity or "Common")
	InsightFrame.Rarity.TextColor3 = rarityInfo.Color
	InsightFrame.Rarity.UIStroke.Color = rarityInfo.StrokeColor

	-- Tips
	local tips = TipsUtility.GetItemConfigTips(itemConfig)
	TipsUtility.UpdateTips(TipsFrame, tips, 10)

	-- Update Viewport
	ViewportUtil.UpdateItemViewport(itemName, Preview)

	-- Set Price

	InsightFrame.Buy.Price.Text = CashUtility.Format(price, {
		fullNumber = false,
		decimals = 0
	})

	-- Show Buy Button
	InsightFrame.Buy.Visible = true

	-- Setup Buy Button Logic
	local buyButton = InsightFrame.Buy

	currentInsightTrove:Add(RunService.RenderStepped:Connect(function()
		ButtonUtility.SetButtonState(buyButton, canAfford(price, levelRequirement))
	end))

	currentInsightTrove:Add(buyButton.MouseButton1Click:Connect(function()
		if canAfford(price, levelRequirement) then
			ButtonUtility.ButtonPush(buyButton)
			Ui.PlaySound("Purchase")
			if buyCallback then
				buyCallback()
			end
		else
			Ui.PlaySound("Error")
		end
	end))

	-- Ensure InsightFrame is visible
	InsightFrame.Visible = true
end

function Insight.Close()
	-- Destroy trove to clean up connections
	if currentInsightTrove then
		currentInsightTrove:Destroy()
		currentInsightTrove = nil
	end

	-- Reset UI Text
	InsightFrame.Title.Text = "(Select an item)"
	InsightFrame.Description.Text = ""
	InsightFrame.Rarity.Text = ""
	InsightFrame.Buy.Price.Text = ""

	-- Hide Buy Button
	InsightFrame.Buy.Visible = false

	-- Hide InsightFrame (optional, depending on overall UI flow)
	InsightFrame.Visible = false

	-- TODO: Clear Viewport
	-- ViewportUtil.ClearViewport(Preview) -- You might need to add a ClearViewport function to ViewportUtil
end

return Insight
