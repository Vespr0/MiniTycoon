local AnalyticsUtility = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

--[[
    Utility functions for analytics to avoid code repetition and handle admin filtering
]]

-- Check if a player is an admin and should be excluded from analytics
function AnalyticsUtility.IsPlayerAdmin(player: Player): boolean
	if not player then
		return false
	end

	for _, adminUserId in GameConfig.AdminUserIds do
		if player.UserId == adminUserId then
			return true
		end
	end

	return false
end

-- Check if analytics should be logged for this player (not an admin)
function AnalyticsUtility.ShouldLogAnalytics(player: Player): boolean
	return not AnalyticsUtility.IsPlayerAdmin(player)
end

-- Validate player parameter and check if analytics should be logged
function AnalyticsUtility.ValidatePlayer(player: Player): boolean
	if not player then
		warn("AnalyticsUtility: Player parameter is nil")
		return false
	end

	if not AnalyticsUtility.ShouldLogAnalytics(player) then
		-- Silently skip analytics for admin players
		return false
	end

	return true
end

-- Validate enum value exists
function AnalyticsUtility.ValidateEnum(enumType: any, value: string): boolean
	local success, result = pcall(function()
		return enumType[value] ~= nil
	end)

	return success and result
end

-- Format custom field for analytics (consistent naming convention)
function AnalyticsUtility.FormatCustomField(fieldName: string, value: any): string
	return `{fieldName} - {tostring(value)}`
end

-- Create custom fields table for analytics events
function AnalyticsUtility.CreateCustomFields(field1: string?, field2: string?, field3: string?): { [string]: string }
	local customFields = {}

	if field1 then
		customFields[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = field1
	end

	if field2 then
		customFields[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = field2
	end

	if field3 then
		customFields[Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = field3
	end

	return customFields
end

-- Validate and format amount for economy events
function AnalyticsUtility.ValidateAmount(amount: number): boolean
	if type(amount) ~= "number" then
		warn("AnalyticsUtility: Amount must be a number")
		return false
	end

	if amount < 0 then
		warn("AnalyticsUtility: Amount cannot be negative")
		return false
	end

	return true
end

-- Validate and format balance for economy events
function AnalyticsUtility.ValidateBalance(balance: number): boolean
	if type(balance) ~= "number" then
		warn("AnalyticsUtility: Balance must be a number")
		return false
	end

	if balance < 0 then
		warn("AnalyticsUtility: Balance cannot be negative")
		return false
	end

	return true
end

return AnalyticsUtility
