local LoadingUtility = {}

-- Topological sort for dependency resolution
function LoadingUtility.ResolveDependencies(modules)
	local moduleMap = {}
	local dependencyGraph = {}
	local inDegree = {}
	local sortedModules = {}
	
	-- Build module map and initialize dependency tracking
	for _, moduleData in pairs(modules) do
		local moduleName = moduleData.module.Name
		moduleMap[moduleName] = moduleData
		dependencyGraph[moduleName] = {}
		inDegree[moduleName] = 0
	end
	
	-- Build dependency graph
	for _, moduleData in pairs(modules) do
		local moduleName = moduleData.module.Name
		local dependencies = moduleData.dependencies or {}
		
		for _, dependency in pairs(dependencies) do
			if moduleMap[dependency] then
				table.insert(dependencyGraph[dependency], moduleName)
				inDegree[moduleName] = inDegree[moduleName] + 1
			else
				warn("Module '" .. moduleName .. "' depends on '" .. dependency .. "' which was not found!")
			end
		end
	end
	
	-- Kahn's algorithm for topological sorting
	local queue = {}
	for moduleName, degree in pairs(inDegree) do
		if degree == 0 then
			table.insert(queue, moduleName)
		end
	end
	
	while #queue > 0 do
		local current = table.remove(queue, 1)
		table.insert(sortedModules, moduleMap[current])
		
		for _, dependent in pairs(dependencyGraph[current]) do
			inDegree[dependent] = inDegree[dependent] - 1
			if inDegree[dependent] == 0 then
				table.insert(queue, dependent)
			end
		end
	end
	
	-- Check for circular dependencies
	if #sortedModules ~= #modules then
		error("Circular dependency detected in module loading!")
	end
	
	return sortedModules
end

-- Collect modules with Setup functions from folders
function LoadingUtility.CollectModules(folders)
	local modules = {}
	
	for _, folder in pairs(folders) do
		for _, module in pairs(folder:GetChildren()) do
			if not module:IsA("ModuleScript") then continue end
			
			local success, required = pcall(require, module)
			if success and required and required.Setup then
				local dependencies = required.Dependencies or {}
				table.insert(modules, {
					module = module,
					required = required,
					dependencies = dependencies
				})
			elseif not success then
				warn("Failed to require module: " .. module.Name .. " - " .. tostring(required))
			end
		end
	end
	
	return modules
end

-- Load modules in dependency order
function LoadingUtility.LoadModules(modules, progressCallback, contextCallback)
	local totalModules = #modules
	
	for i, moduleData in pairs(modules) do
		if contextCallback then
			contextCallback("Loading " .. moduleData.module.Name)
		end
		
		if progressCallback then
			progressCallback((i - 1) / totalModules)
		end
		
		local success, err = pcall(moduleData.required.Setup)
		if not success then
			warn("Failed to setup module: " .. moduleData.module.Name .. " - " .. tostring(err))
		end
	end
	
	if progressCallback then
		progressCallback(1)
	end
end

return LoadingUtility