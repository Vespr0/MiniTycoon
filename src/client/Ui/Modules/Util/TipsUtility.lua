local TipsUtility = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local AssetsDealer = require(Shared.AssetsDealer)
local UiUtility = require(script.Parent.Parent.Parent.UiUtility)

-- Constants
local TEXTURE_DIRECTORY_PREAMBLE = "Ui/Tips"

function TipsUtility.CreateTipIcon(name)
    local tipTexture = AssetsDealer.GetTexture(`{TEXTURE_DIRECTORY_PREAMBLE}/{name}`)
    if not tipTexture then
        warn(`Tip icon not found with name "{name}`)
        tipTexture = AssetsDealer.GetTexture(`Missing`)
    end

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = tipTexture
    
    local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
    uiAspectRatioConstraint.Parent = imageLabel

    return imageLabel    
end

function TipsUtility.GetItemConfigTips(itemConfig)
    local canPlaceOnGround = itemConfig.CanPlaceOnGround
	local canPlaceOnWater = itemConfig.CanPlaceOnWater

    local tips = {}
	if not canPlaceOnGround then
		table.insert(tips, "CannotPlaceOnGround")
	end
	if canPlaceOnWater then
		table.insert(tips, "CanPlaceOnWater")
	end
	
    return tips
end

-- Tips is an array of strings
function TipsUtility.UpdateTips(frame: Frame, tips: {string}, zIndex: number)
    -- Clear the frame from existing tip icons
    UiUtility.ClearFrame(frame)

    -- For each tip name create a tip icon and add it to the frame
    for _, tipName in ipairs(tips) do
        local tipIcon = TipsUtility.CreateTipIcon(tipName)
        tipIcon.Parent = frame
        tipIcon.ZIndex = zIndex
    end
end

return TipsUtility