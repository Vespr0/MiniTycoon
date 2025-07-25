-- TestingManager: Runs all scripts in the Tests folder that have a Run function
local TestingManager = {}

-- local ServerScriptService = game:GetService("ServerScriptService")
local TestsFolder = script.Parent:FindFirstChild("Tests")

function TestingManager.Run(testName)
	local testModuleName = testName .. "Test"
	local testModule = TestsFolder:FindFirstChild(testModuleName)

	if not testModule then
		warn(`🧪 Test not found: {testModuleName}`)
		return
	end

	if not testModule:IsA("ModuleScript") then
		warn(`🧪 {testModuleName} is not a ModuleScript`)
		return
	end

	local success, module = pcall(require, testModule)
	if not success then
		warn(`🧪 Error requiring {testModuleName}: {tostring(module)}`)
		return
	end

	if not module.Run then
		warn(`🧪 Module {testModuleName} does not have a Run function.`)
		return
	end

	print(`🧪 Running test: {testModuleName}`)
	local ok, err = pcall(module.Run)
	if not ok then
		error(`❌ Test failed: {testModuleName} : {tostring(err)}`)
	else
		print(`✅ Test passed: {testModuleName}`)
	end
end

function TestingManager.RunAll()
	for _, testModule in TestsFolder:GetChildren() do
		if testModule:IsA("ModuleScript") then
			task.spawn(function()
				local success, module = pcall(require, testModule)

				if not success then
					warn(`🧪 Error requiring {testModule.Name}: {tostring(module)}`)
				end

				if not module.Enabled then
					return
				end

				if not module.Run then
					warn(`🧪 Module {testModule.Name} does not have a Run function.`)
					return
				end

				print(`🧪 Running test: {testModule.Name}`)
				local ok, err = pcall(module.Run)
				if not ok then
					error(`❌ Test failed: {testModule.Name} : {tostring(err)}`)
				else
					--print(string.format("[TestingManager] Test passed: {%s}", testModule.Name))
				end
			end)
		end
	end
end

return TestingManager
