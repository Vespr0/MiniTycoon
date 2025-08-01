local SettingsInfo = {}

-- Setting types enum
SettingsInfo.SettingTypes = {
	Switch = "Switch",
	NumberSlide = "NumberSlide",
	PercentageSlide = "PercentageSlide",
	TextBox = "TextBox",
}

-- Get setting info by name
function SettingsInfo.GetSettingInfo(settingName)
	local info = SettingsInfo.Settings[settingName]
	if not info then
		warn("Setting info not found for: " .. settingName)
		return nil
	end
	return info
end

-- Validate setting value based on type
-- function SettingsInfo.ValidateSettingValue(settingName, value)
-- 	local info = SettingsInfo.GetSettingInfo(settingName)
-- 	if not info then
-- 		return false, "Setting not found"
-- 	end

-- 	if info.Type == SettingsInfo.SettingTypes.Switch then
-- 		return type(value) == "boolean", "Value must be boolean"
-- 	elseif info.Type == SettingsInfo.SettingTypes.NumberSlide then
-- 		if type(value) ~= "number" then
-- 			return false, "Value must be number"
-- 		end
-- 		if info.Min and value < info.Min then
-- 			return false, "Value below minimum: " .. info.Min
-- 		end
-- 		if info.Max and value > info.Max then
-- 			return false, "Value above maximum: " .. info.Max
-- 		end
-- 		return true
-- 	elseif info.Type == SettingsInfo.SettingTypes.PercentageSlide then
-- 		if type(value) ~= "number" then
-- 			return false, "Value must be number"
-- 		end
-- 		if value < 0 or value > 100 then
-- 			return false, "Percentage must be between 0 and 100"
-- 		end
-- 		return true
-- 	elseif info.Type == SettingsInfo.SettingTypes.TextBox then
-- 		if type(value) ~= "string" then
-- 			return false, "Value must be string"
-- 		end
-- 		if info.MaxLength and #value > info.MaxLength then
-- 			return false, "Text exceeds maximum length: " .. info.MaxLength
-- 		end
-- 		return true
-- 	end

-- 	return false, "Unknown setting type"
-- end

-- Settings definitions
SettingsInfo.Settings = {
	ColorBlindMode = {
		Name = "ColorBlindMode",
		Title = "Color Blind Mode",
		Description = "Enables color blind friendly mode.",
		Type = SettingsInfo.SettingTypes.Switch,
		DefaultValue = false,
		Category = "Accessibility",
	},

	MusicVolume = {
		Name = "MusicVolume",
		Title = "Music Volume",
		Description = "Controls the volume level of background music.",
		Type = SettingsInfo.SettingTypes.PercentageSlide,
		DefaultValue = 50,
		Category = "Audio",
	},

	Particles = {
		Name = "Particles",
		Title = "Particles",
		Description = "Enables or disables particle effects.",
		Type = SettingsInfo.SettingTypes.Switch,
		DefaultValue = true,
		Category = "Graphics",
	},
}

return SettingsInfo
