
-- TestingManager: Runs all scripts in the Tests folder that have a Run function
local TestingManager = {}

-- local ServerScriptService = game:GetService("ServerScriptService")
local TestsFolder = script.Parent:FindFirstChild("Tests")

function TestingManager.RunAll()
    for _, testModule in TestsFolder:GetChildren() do
        if testModule:IsA("ModuleScript") then
            task.spawn(function()
                local success, module = pcall(require, testModule)

                if not success then
                    warn(`[TestingManager] Error requiring {testModule.Name}: {tostring(module)}`)
                end
                
                if not module.Enabled then return end

                if not module.Run then
                    warn(`[TestingManager] Module {testModule.Name} does not have a Run function.`)
                    return
                end
                
                print(`[TestingManager] Running test: {testModule.Name}`)
                local ok, err = pcall(module.Run)
                if not ok then
                    warn(`[TestingManager] Test failed: {testModule.Name} : {tostring(err)}`)
                else
                    --print(string.format("[TestingManager] Test passed: {%s}", testModule.Name))
                end
            end)
        end
    end
end

return TestingManager
