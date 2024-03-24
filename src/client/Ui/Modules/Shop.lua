local Shop = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Ui Modules
local Ui = require(script.Parent.Parent.UiUtility)
local OffersUi = require(script.Parent.Offers)

-- Ui Elements 
local Gui = Ui.ShopGui
local MainFrame = Ui.ShopMainFrame
local OffersFrame = MainFrame:WaitForChild("OffersFrame")
local FragumFrame = MainFrame:WaitForChild("FragumFrame")
local SectionSelectors = MainFrame:WaitForChild("SectionSelectors")
Shop.OffersFrame = OffersFrame

-- Modules --
local ItemInfo = require(Shared.Items.ItemInfo)
local AssetsDealer = require(Shared.AssetsDealer)

-- Constants --
local ORIGIN = MainFrame.Position
local TYPE_SELECTORS = {SectionSelectors.Offers,SectionSelectors.Fragum}

-- Variables --
local trove = require(Packages.trove).new()
local CurrentSection

-- Modules --
local ItemUtility = require(Shared.Items.ItemUtility)

-- Functions
local function tweenPopup(goal)
    local tween = TweenService:Create(MainFrame,Ui.MENU_TWEEN_INFO,{Position = goal})
    tween:Play()
end

local function tweenTypeSelector(button,goal)
    local tween = TweenService:Create(button,Ui.MENU_TWEEN_INFO,{ImageColor3 = goal})
    tween:Play()
end

local function updateTypeSelectors()
    for _,typeSelector in pairs(TYPE_SELECTORS) do
        local isSelectedType = typeSelector.Name == CurrentSection
        tweenTypeSelector(typeSelector,isSelectedType and Ui.BUTTON_SELECTED_COLOR or Ui.BUTTON_UNSELECTED_COLOR)
    end
end

function Shop.SwitchToDailyOffers()
    OffersUi.Open()
end

function Shop.SwitchToFragum()
    OffersUi.Close()
end

-- Module Functions
function Shop.Open()
    Gui.Enabled = true
    MainFrame.Position = ORIGIN+UDim2.fromScale(0,1)
    tweenPopup(ORIGIN)
    Shop.SwitchToDailyOffers()
end

function Shop.Close()
    MainFrame.Position = ORIGIN
    tweenPopup(ORIGIN+UDim2.fromScale(0,1))
    task.wait(Ui.MENU_TWEEN_INFO.Time)
    Gui.Enabled = false
end

function Shop.Setup()
    Gui.Enabled = false

    for _,sectionSelector in pairs(TYPE_SELECTORS) do
        sectionSelector.MouseButton1Click:Connect(function()
            CurrentSection = sectionSelector.Name
            updateTypeSelectors()
        end)
    end
end

return Shop