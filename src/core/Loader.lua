local Promise = require("../modules/thirdparty/Promise")

--[=[
	@class Loader

	From Stephen Leitnick's Loader from RbxUtil.
	Modified with additional methods and error handling.

	```lua
	local MyModules = ReplicatedStorage.MyModules
	Loader.SpawnAll(
		Loader.LoadDescendants(MyModules, Loader.MatchesName("Service$")),
		"OnStart"
	)
	```
]=]
local Loader = {}

--[=[
	@within Loader
	@type PredicateFn (module: ModuleScript) -> boolean
	Predicate function type.
]=]
type PredicateFn = (module: ModuleScript) -> boolean

--[=[
	Requires all children ModuleScripts.

	If a `predicate` function is provided, then the module will only
	be loaded if the predicate returns `true` for the the given
	ModuleScript.

	```lua
	-- Load all ModuleScripts directly under MyModules:
	Loader.LoadChildren(ReplicatedStorage.MyModules)

	-- Load all ModuleScripts directly under MyModules if they have names ending in 'Service':
	Loader.LoadChildren(ReplicatedStorage.MyModules, function(moduleScript)
		return moduleScript.Name:match("Service$") ~= nil
	end)
	```
]=]
function Loader.LoadChildren(parent: Instance, predicate: PredicateFn?): { [string]: any }
	return Promise.new(function(resolve, _reject)
		local modules: { [string]: any } = {}
		local promises = {}

		for _, child in parent:GetChildren() do
			if child:IsA("ModuleScript") then
				if predicate and not predicate(child) then
					continue
				end

				local promise = Promise.try(function()
					return require(child)
				end):andThen(function(m)
					modules[child.Name] = m
				end):catch(function(_err)
					-- Ignore errors silently or log them if needed
				end)

				table.insert(promises, promise)
			end
		end

		Promise.all(promises):andThen(function()
			resolve(modules)
		end)
	end)
end

--[=[
	Requires all descendant ModuleScripts.

	If a `predicate` function is provided, then the module will only
	be loaded if the predicate returns `true` for the the given
	ModuleScript.

	```lua
	-- Load all ModuleScripts under MyModules:
	Loader.LoadDescendants(ReplicatedStorage.MyModules)

	-- Load all ModuleScripts under MyModules if they have names ending in 'Service':
	Loader.LoadDescendants(ReplicatedStorage.MyModules, function(moduleScript)
		return moduleScript.Name:match("Service$") ~= nil
	end)
	```
]=]
function Loader.LoadDescendants(parent: Instance, predicate: PredicateFn?): { [string]: any }
	return Promise.new(function(resolve, _reject)
		local modules: { [string]: any } = {}
		local promises = {}

		for _, child in parent:GetDescendants() do
			if child:IsA("ModuleScript") then
				if predicate and not predicate(child) then
					continue
				end

				local promise = Promise.try(function()
					return require(child)
				end):andThen(function(m)
					modules[child.Name] = m
				end):catch(function(_err)
					-- Ignore errors silently or log them if needed
				end)

				table.insert(promises, promise)
			end
		end

		Promise.all(promises):andThen(function()
			resolve(modules)
		end)
	end)
end

--[=[
	Utility function for spawning a specific method in all given modules.
	If a module does not contain the specified method, it is simply
	skipped. Methods are called with `task.spawn` internally.

	For example, if the modules are expected to have an `OnStart()` method,
	then `SpawnAll()` could be used to start all of them directly after
	they have been loaded:

	```lua
	local MyModules = ReplicatedStorage.MyModules

	-- Load all modules under MyModules and then call their OnStart methods:
	Loader.SpawnAll(Loader.LoadDescendants(MyModules), "OnStart")

	-- Same as above, but only loads modules with names that end with Service:
	Loader.SpawnAll(
		Loader.LoadDescendants(MyModules, Loader.MatchesName("Service$")),
		"OnStart"
	)
	```
]=]
function Loader.SpawnAll(loadedModules: { [string]: any }, methodName: string)
	for name, mod in loadedModules do
		local method = mod[methodName]
		if type(method) == "function" then
			print(mod)
			task.spawn(function()
				debug.setmemorycategory(name)
				method(mod)
			end)
		end
	end
end

function Loader.LoadAndSpawnDescendants(parent: Instance, methodName: string, predicate: PredicateFn?)
	return Promise.new(function()
		for _, child in parent:GetDescendants() do
			if child:IsA("ModuleScript") then
				if predicate and not predicate(child) then
					continue
				end

				Promise.try(function()
					return require(child)
				end):andThen(function(mod)
					local method = mod[methodName]
					if type(method) == "function" then
						task.spawn(function()
							debug.setmemorycategory(child.Name)
							method(mod)
						end)
					end
				end):catch(function(err)
					-- Optionally log or ignore
				end)
			end
		end
	end)
end

--[=[
	Similar to `Loader.SpawnAll()`, connects a function of all given modules
	to a given connection, then returns a table of the connections.

	```lua
	local RunService = game:GetService("RunService")
	local MyModules = ReplicatedStorage.MyModules

	-- Load all modules under MyModules and then connect their "Hearbeat" function
	-- to RunService.Heartbeat
	Loader.SpawnAll(Loader.LoadDescendants(MyModules), "Hearbeat", RunService.Heartbeat)
	```
]=]
function Loader.BindAll(loadedModules: { [string]: any }, methodName: string, connection: RBXScriptSignal)
	local connections = {}

	for name, mod in loadedModules do
		local method = mod[methodName]
		if type(method) == "function" then
			connections[ #connections + 1 ] = connection:Connect(method)
		end
	end

	return connections
end

return Loader