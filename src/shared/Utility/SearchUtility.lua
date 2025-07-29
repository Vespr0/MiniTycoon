--[[
	SearchUtility - Hybrid search engine for string matching
	Combines exact prefix matching, fuzzy matching, and substring matching
	with relevance scoring for optimal search results
]]

local SearchUtility = {}

-- Configuration constants


--[[
	This constant controls the minimum similarity score required for a match to be considered valid
	in full fuzzy matching. 

	Lower (e.g., 0.2) → More lenient, includes more distant matches
	Higher (e.g., 0.6) → More strict, only very similar strings pass
]]
local FUZZY_THRESHOLD = 0.2

--[[
	This constant controls the minimum similarity score for fuzzy prefix matching, which checks if
	the query is similar to the beginning of the target string.

	Lower (e.g., 0.5) → More forgiving of prefix typos
	Higher (e.g., 0.9) → Requires very accurate prefix typing
]]
local FUZZY_PREFIX_THRESHOLD = 0.4 -- Minimum similarity for fuzzy prefix matches

-- Calculate Levenshtein distance between two strings
local function levenshteinDistance(str1, str2)
	local len1, len2 = #str1, #str2
	local matrix = {}

	-- Initialize matrix
	for i = 0, len1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2 do
		matrix[0][j] = j
	end

	-- Fill matrix
	for i = 1, len1 do
		for j = 1, len2 do
			local cost = (str1:sub(i, i) == str2:sub(j, j)) and 0 or 1
			matrix[i][j] = math.min(
				matrix[i - 1][j] + 1, -- deletion
				matrix[i][j - 1] + 1, -- insertion
				matrix[i - 1][j - 1] + cost -- substitution
			)
		end
	end

	return matrix[len1][len2]
end

-- Calculate similarity score (0-1, higher is better)
local function calculateSimilarity(query, target)
	local queryLower = query:lower()
	local targetLower = target:lower()

	-- Exact match gets highest score
	if queryLower == targetLower then
		return 1.0
	end

	-- Prefix match gets high score
	if targetLower:sub(1, #queryLower) == queryLower then
		return 0.9
	end

	-- Substring match gets good score
	if targetLower:find(queryLower, 1, true) then
		return 0.7
	end

	-- Check if query is similar to the beginning of target (fuzzy prefix)
	local prefixLen = math.min(#queryLower + 2, #targetLower)
	local targetPrefix = targetLower:sub(1, prefixLen)
	local prefixDistance = levenshteinDistance(queryLower, targetPrefix)
	local prefixSimilarity = 1 - (prefixDistance / math.max(#queryLower, prefixLen))

	if prefixSimilarity > FUZZY_PREFIX_THRESHOLD then
		return prefixSimilarity * 0.8 -- High score for fuzzy prefix matches
	end

	-- Full fuzzy matching using Levenshtein distance
	local distance = levenshteinDistance(queryLower, targetLower)
	local maxLen = math.max(#queryLower, #targetLower)

	if maxLen == 0 then
		return 0
	end

	local similarity = 1 - (distance / maxLen)

	-- Use configurable threshold for fuzzy matches
	return similarity > FUZZY_THRESHOLD and similarity * 0.6 or 0
end

-- Search function that returns ranked results
function SearchUtility.search(query, items, options)
	options = options or {}
	local maxResults = options.maxResults or 10
	local minScore = options.minScore or 0.1

	if not query or query == "" then
		return {}
	end

	local results = {}

	-- Score all items
	for _, item in ipairs(items) do
		local score = calculateSimilarity(query, item)
		if score >= minScore then
			table.insert(results, {
				item = item,
				score = score,
			})
		end
	end

	-- Sort by score (highest first)
	table.sort(results, function(a, b)
		return a.score > b.score
	end)

	-- Extract items and limit results
	local finalResults = {}
	for i = 1, math.min(#results, maxResults) do
		table.insert(finalResults, results[i].item)
	end

	return finalResults
end

-- Search function that returns results with scores (for debugging/advanced use)
function SearchUtility.searchWithScores(query, items, options)
	options = options or {}
	local maxResults = options.maxResults or 10
	local minScore = options.minScore or 0.1

	if not query or query == "" then
		return {}
	end

	local results = {}

	-- Score all items
	for _, item in ipairs(items) do
		local score = calculateSimilarity(query, item)
		if score >= minScore then
			table.insert(results, {
				item = item,
				score = score,
			})
		end
	end

	-- Sort by score (highest first)
	table.sort(results, function(a, b)
		return a.score > b.score
	end)

	-- Limit results
	local finalResults = {}
	for i = 1, math.min(#results, maxResults) do
		table.insert(finalResults, results[i])
	end

	return finalResults
end

return SearchUtility
