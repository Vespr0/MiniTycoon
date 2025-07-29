--[[
	SearchUtilityTest - Test suite for SearchUtility
	Tests exact matching, prefix matching, substring matching, and fuzzy matching
]]

local SearchUtility = require(game.ReplicatedStorage.Shared.Utility.SearchUtility)

local SearchUtilityTest = {}

SearchUtilityTest.Enabled = true

-- Test data - actual items from the tycoon game ShopInfo
local testItems = {
	-- Droppers
	"CoalMine",
	"IronMine",
	"LargeCoalMine",
	"QuartzMine",
    "QuartzPedastal",
	"UraniumLazur",

	-- Conveyor Belts
	"OldBelt",
	"IceBelt",

	-- Upgraders
	"OldWasher",
	"UraniumInfuser",

	-- Forge
	"OldForge",

	-- Decorations
	"SmallTree",
}

-- Helper function to run a test case
local function runTest(testName, query, expectedResults, shouldContain)
	local results = SearchUtility.search(query, testItems, { maxResults = 5 })

	if shouldContain then
		-- Check if results contain expected items
		local found = {}
		for _, expected in ipairs(expectedResults) do
			for _, result in ipairs(results) do
				if result == expected then
					found[expected] = true
					break
				end
			end
		end

		for _, expected in ipairs(expectedResults) do
			if not found[expected] then
				error(
					"❌ "
						.. testName
						.. " FAILED: Expected to find '"
						.. expected
						.. "' but didn't. Query: '"
						.. query
						.. "', Results: "
						.. table.concat(results, ", ")
				)
			end
		end
	else
		-- Check exact order match
		for i, expected in ipairs(expectedResults) do
			if results[i] ~= expected then
				error(
					"❌ "
						.. testName
						.. " FAILED: Expected '"
						.. (expected or "nil")
						.. "' at position "
						.. i
						.. ", got '"
						.. (results[i] or "nil")
						.. "'. Query: '"
						.. query
						.. "'"
				)
			end
		end
	end
end

function SearchUtilityTest.Run()
	-- Test 1: Exact match
	runTest("Exact Match", "CoalMine", { "CoalMine" }, false)

	-- Test 2: Prefix match
	runTest("Prefix Match", "Old", { "OldBelt", "OldWasher", "OldForge" }, true)

	-- Test 3: Substring match
	runTest("Substring Match", "Mine", { "CoalMine", "IronMine", "LargeCoalMine", "QuartzMine" }, true)

	-- Test 4: Case insensitive
	runTest("Case Insensitive", "URANIUM", { "UraniumLazur", "UraniumInfuser" }, true)

	-- Test 5: Fuzzy match (typo)
	runTest("Fuzzy Match - Typo", "Quarzt", { "QuartzMine", "QuartzPedastal" }, true)

	-- Test 6: Multiple word match (camelCase)
	runTest("CamelCase Match", "Coal", { "CoalMine", "LargeCoalMine" }, true)

	-- Test 7: Partial word in compound
	runTest("Partial Word in Compound", "Belt", { "OldBelt", "IceBelt" }, true)

	-- Test 8: Priority test (exact should come before substring)
	runTest("Priority Test", "IronMine", { "IronMine" }, false)

	-- Test 9: Empty query
	runTest("Empty Query", "", {}, false)

	-- Test 10: No matches
	runTest("No Matches", "xyz123", {}, false)

	-- Test 11: Fuzzy match with multiple results
	runTest("Fuzzy Multiple Results", "Infusr", { "UraniumInfuser" }, true)

	-- Test 12: Complex search
	runTest("Complex Search", "Tree", { "SmallTree" }, true)
end

return SearchUtilityTest
