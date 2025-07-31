-- Test script to verify dependency resolution
local LoadingUtility = require("src/shared/Utility/LoadingUtility")

-- Mock modules for testing
local mockModules = {
	{
		module = {Name = "Menu"},
		required = {Setup = function() print("Menu Setup") end},
		dependencies = {}
	},
	{
		module = {Name = "Shop"},
		required = {Setup = function() print("Shop Setup") end},
		dependencies = {"Menu"}
	},
	{
		module = {Name = "Storage"},
		required = {Setup = function() print("Storage Setup") end},
		dependencies = {"Menu"}
	},
	{
		module = {Name = "ControlPanel"},
		required = {Setup = function() print("ControlPanel Setup") end},
		dependencies = {"Menu", "Upgrades"}
	},
	{
		module = {Name = "Upgrades"},
		required = {Setup = function() print("Upgrades Setup") end},
		dependencies = {}
	}
}

print("Testing dependency resolution...")
local sortedModules = LoadingUtility.ResolveDependencies(mockModules)

print("\nLoad order:")
for i, moduleData in pairs(sortedModules) do
	print(i .. ". " .. moduleData.module.Name)
end

print("\nExpected order: Menu, Upgrades, Shop, Storage, ControlPanel")
print("(Menu and Upgrades can be in any order since they have no dependencies)")