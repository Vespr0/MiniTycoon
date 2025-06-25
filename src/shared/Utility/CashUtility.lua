local CashUtility = {}

-- Configuration options for formatting
local CONFIG = {
	-- Minimum absolute value to start shortening (e.g., 100_000 for 100K)
	SHORTEN_MIN = 100000,
	-- Number of digits to keep when shortening (e.g., 2 for 2.55M)
	SHORTEN_DECIMAL_PLACES = 2,
	-- Default number of decimal places for full number display
	FULL_NUMBER_DECIMAL_PLACES = 2,
	-- If true, uses ',' for thousands and '.' for decimals (e.g., 1.000.000,23)
	-- If false, uses '.' for thousands and ',' for decimals (e.g., 1,000,000.23)
	INVERSE_SEPARATORS = true,
	-- Display currency symbol (e.g., "$ 100")
	DISPLAY_CURRENCY_SYMBOL = true,
	-- Currency symbol to use
	CURRENCY_SYMBOL = "$ ",
}

-- Suffixes for shortened numbers
local SUFFIXES = {
	{ threshold = 1e12, suffix = "T" }, -- Trillion
	{ threshold = 1e9, suffix = "B" }, -- Billion
	{ threshold = 1e6, suffix = "M" }, -- Million
	{ threshold = 1e3, suffix = "K" }, -- Thousand
}

--- Formats a number by inserting thousand separators and handling decimals.
-- @param numStr string The number as a string (e.g., "1234567.89").
-- @param thousandSep string The thousand separator (e.g., "." or ",").
-- @param decimalSep string The decimal separator (e.g., "," or ".").
-- @return string The formatted number string.
local function formatWithSeparators(numStr, thousandSep, decimalSep)
	local integerPart, decimalPart = numStr:match("^(%-?%d+)[%.,]?(%d*)$")
	integerPart = integerPart or numStr

	-- Insert thousand separators into the integer part
	integerPart = integerPart:reverse():gsub("(%d%d%d)", "%1" .. thousandSep)
	integerPart = integerPart:reverse()

	-- Remove leading thousand separator if present (e.g., ".123" -> "123")
	if integerPart:sub(1, #thousandSep) == thousandSep then
		integerPart = integerPart:sub(#thousandSep + 1)
	end
	
	-- Handle negative numbers edge case (e.g. if the number is -123, you might get "-.123")
	if integerPart:sub(1, #thousandSep + 1) == "-" .. thousandSep then
		integerPart = "-" .. integerPart:sub(#thousandSep + 2)
	end

	-- Combine integer and decimal parts
	if decimalPart and #decimalPart > 0 then
		return integerPart .. decimalSep .. decimalPart
	else
		return integerPart
	end
end

--- Formats a cash value.
-- @param value number The cash value to format.
-- @param options table Optional table for custom formatting:
--        - `fullNumber` boolean: If true, always display the full number with separators, no shortening.
--        - `decimals` number: Number of decimal places to display (overrides default).
-- @return string The formatted cash string.
function CashUtility.Format(value, options)
	options = options or {}
	local fullNumberMode = options.fullNumber or false
	local displayDecimals = options.decimals

	local absValue = math.abs(value)
	local suffix = ""
	local formattedValue = value

	local thousandSep, decimalSep = ".", ","
	if CONFIG.INVERSE_SEPARATORS then
		thousandSep, decimalSep = ",", "."
	end

	if not fullNumberMode and absValue >= CONFIG.SHORTEN_MIN then
		-- Shorten the number
		for _, data in ipairs(SUFFIXES) do
			if absValue >= data.threshold then
				formattedValue = value / data.threshold
				suffix = data.suffix
				break
			end
		end

		-- Format shortened number
		local formatString = string.format("%%.%df", CONFIG.SHORTEN_DECIMAL_PLACES)
		formattedValue = string.format(formatString, formattedValue)
		
		-- Remove trailing zeros and decimal point if they become redundant
		formattedValue = formattedValue:gsub("%.?0+$", "")
		
	else
		-- Display full number with separators
		local effectiveDecimals = displayDecimals ~= nil and displayDecimals or CONFIG.FULL_NUMBER_DECIMAL_PLACES
		local formatString = string.format("%%.%df", effectiveDecimals)
		formattedValue = string.format(formatString, value)

		-- Use a dot for string.format's decimal for consistency, then replace for display
		formattedValue = formattedValue:gsub("-(%d+).", "-%1#") -- Temporarily protect negative sign with a dummy char
		formattedValue = formattedValue:gsub("%.", "#") -- Temporarily replace original decimal to avoid confusion
		formattedValue = formatWithSeparators(formattedValue:gsub("#", "."), thousandSep, decimalSep)
	end

	local finalString = (CONFIG.DISPLAY_CURRENCY_SYMBOL and CONFIG.CURRENCY_SYMBOL or "") .. tostring(formattedValue) .. suffix
	return finalString
end

return CashUtility