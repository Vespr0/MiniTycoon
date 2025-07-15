local Popup = {}

-- Get Popup GUI from PlayerGui
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local ViewportUtil = require(script.Parent.Util.Viewport)
local TweenUtil = require(script.Parent.Util.Tween)
local CashUtility = require(game.ReplicatedStorage.Shared.Utility.CashUtility)

-- Wait for Popup GUI and its children
local PopupGui = PlayerGui:WaitForChild("Popup")
local MainFrame = PopupGui:WaitForChild("MainFrame")
local ItemTemplate = MainFrame:WaitForChild("ItemTemplate")
ItemTemplate.Parent = script

local TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Sine)

-- Store references
Popup.MainFrame = MainFrame
Popup.ItemTemplate = ItemTemplate

function Popup.GenerateItemPurchaseMessage(itemName, price, itemConfig)
     local cashString = CashUtility.Format(price, {
        fullNumber = false,
        decimals = 0
    })
    local itemDisplayName = itemConfig.DisplayName or itemName
    return `Bought x{1} <b>{itemDisplayName}</b> for <b>{cashString}</b> `
end

--[[
    Creates a new itemTemplate, puts in the main frame (the ui list layout will display the items vertically)
    items will be pushed in the MainFrame and then will fade out like a queue.
]]
function Popup.Enqueue(itemName: string, message: string?, count: number?)
    
    local itemTemplate = ItemTemplate:Clone()
    itemTemplate.Parent = MainFrame -- Add to the main frame
    itemTemplate.Name = itemName

    local innerFrame = itemTemplate:WaitForChild("InnerFrame")
    innerFrame.Message.Text = message or "Bought " .. itemName

    innerFrame.ViewportFrame.Count.Text = (`x{count}`) or `x1`

    -- The inner frame starts our of screen and tweens left to right
    innerFrame.Position = UDim2.new(1, 0, 0, 0) -- Start off-screen to the right
    -- Tween to bring it into view
    TweenUtil.Generic(innerFrame, {
        Position = UDim2.new(0, 0, 0, 0), -- Move to the center
    }, TWEEN_INFO)

    local viewport = ViewportUtil.CreateItemViewport(itemName,10)
    viewport.Parent = innerFrame.ViewportFrame

    task.spawn(function()
        -- Hide again 
        task.wait(5) -- Wait for a while before hiding
        TweenUtil.Generic(innerFrame, {
            Position = UDim2.new(1, 0, 0, 0), -- Move to the center
        }, TWEEN_INFO)
        task.wait(TWEEN_INFO.Time) -- Wait for the tween to finish
        itemTemplate:Destroy() -- Remove the item template from the UI
    end)
end

function Popup.Setup()

    -- Popup.Enqueue("CoalMine")
end

return Popup
