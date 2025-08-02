--[[
    SearchUtility - Hybrid search engine for string matching
    Combines exact prefix matching, fuzzy matching, and substring matching
    with relevance scoring for optimal search results
]]

local SearchUtility = {}

--[[
    CONFIGURATION CONSTANTS (Tuned for better relevance)
]]

-- CHANGED: Increased threshold to 0.6. Requires a 60% similarity for a fuzzy match.
-- This is the most important change to reduce irrelevant results.
local FUZZY_THRESHOLD = 0.6

-- CHANGED: Increased threshold to 0.75. Requires a more accurate prefix.
local FUZZY_PREFIX_THRESHOLD = 0.75

--[[
    Private Helper Functions
]]

-- Calculate Levenshtein distance between two strings (unchanged)
local function levenshteinDistance(str1, str2)
    local len1, len2 = #str1, #str2
    if len1 == 0 then return len2 end
    if len2 == 0 then return len1 end

    local matrix = {}
    for i = 0, len1 do
        matrix[i] = {}
        matrix[i][0] = i
    end
    for j = 0, len2 do
        matrix[0][j] = j
    end

    for i = 1, len1 do
        for j = 1, len2 do
            local cost = (str1:sub(i, i) == str2:sub(j, j)) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i - 1][j] + 1,       -- deletion
                matrix[i][j - 1] + 1,       -- insertion
                matrix[i - 1][j - 1] + cost -- substitution
            )
        end
    end

    return matrix[len1][len2]
end

-- REFACTORED: Reworked scoring logic for more intuitive and strict ranking.
local function calculateSimilarity(query, target)
    local queryLower = query:lower()
    local targetLower = target:lower()
    local queryLen = #queryLower
    local targetLen = #targetLower

    if queryLen == 0 then return 0 end

    -- 1. Exact Match (Highest Score)
    if queryLower == targetLower then
        return 1.0
    end

    -- 2. Exact Prefix Match (Very High Score)
    if targetLower:sub(1, queryLen) == queryLower then
        -- Score is weighted by length to favor longer matches
        return 0.9 + (0.09 * (queryLen / targetLen))
    end

    -- 3. Fuzzy Prefix Match (High Score)
    -- Check if the query is a slightly misspelled version of the beginning of the target.
    -- We check a prefix of the target that is slightly longer than the query to allow for insertions.
    local prefixCheckLen = math.min(targetLen, queryLen + 2)
    local targetPrefix = targetLower:sub(1, prefixCheckLen)
    local prefixDistance = levenshteinDistance(queryLower, targetPrefix)
    local maxPrefixLen = math.max(queryLen, #targetPrefix)
    local prefixSimilarity = 1 - (prefixDistance / maxPrefixLen)

    if prefixSimilarity >= FUZZY_PREFIX_THRESHOLD then
        -- The score is high, proportional to how good the fuzzy prefix match is.
        -- Ensures it's always higher than a substring match.
        return 0.8 + (prefixSimilarity * 0.09)
    end

    -- 4. Substring Match (Good Score)
    if targetLower:find(queryLower, 1, true) then
        return 0.75
    end

    -- 5. Full Fuzzy Match (Moderate Score)
    local distance = levenshteinDistance(queryLower, targetLower)
    local maxLen = math.max(queryLen, targetLen)
    local similarity = 1 - (distance / maxLen)

    if similarity >= FUZZY_THRESHOLD then
        -- The score is scaled by the similarity itself, ensuring better matches get better scores.
        return similarity * 0.7
    end

    -- No match found
    return 0
end


-- REFACTORED: Internal search function to avoid code duplication.
local function _performSearch(query, items, options)
    options = options or {}
    local maxResults = options.maxResults or 10
    local minScore = options.minScore or 0.1 -- Keep a low minScore here, filtering is done by thresholds

    if not query or query == "" then
        return {}, {}
    end

    local results = {}
    for i, item in ipairs(items) do
        local score = calculateSimilarity(query, item)
        if score >= minScore then
            table.insert(results, { item = item, score = score })
        end
    end

    table.sort(results, function(a, b)
        return a.score > b.score
    end)
    
    -- Return the full sorted list; the public functions will trim it.
    return results, maxResults
end


--[[
    Public API
]]

-- Search function that returns only the matched items.
function SearchUtility.search(query, items, options)
    local sortedResults, maxResults = _performSearch(query, items, options)
    
    local finalResults = {}
    for i = 1, math.min(#sortedResults, maxResults) do
        table.insert(finalResults, sortedResults[i].item)
    end

    return finalResults
end

-- Search function that returns results with scores (for debugging/advanced use).
function SearchUtility.searchWithScores(query, items, options)
    local sortedResults, maxResults = _performSearch(query, items, options)
    
    local finalResults = {}
    for i = 1, math.min(#sortedResults, maxResults) do
        table.insert(finalResults, sortedResults[i])
    end

    return finalResults
end


return SearchUtility