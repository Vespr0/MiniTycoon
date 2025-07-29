-- Debug script to test SearchUtility fuzzy matching
local SearchUtility = require("src/shared/Utility/SearchUtility")

local testItems = {"QuartzMine", "CoalMine", "IronMine"}

print("Testing fuzzy search for 'Quarzt':")
local results = SearchUtility.searchWithScores("Quarzt", testItems)

for i, result in ipairs(results) do
    print(string.format("%d. %s (score: %.3f)", i, result.item, result.score))
end

if #results == 0 then
    print("No results found!")
end