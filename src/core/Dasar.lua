-- Dasar.lua
-- NirlekaDev
-- January 18, 2024

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Loader = require("./Loader")
local ObjectPath = require("./variant/ObjectPath")
local Provider = require("./Provider")
local Promise = require(ReplicatedStorage.src.modules.thirdparty.Promise)

local dir_root = ReplicatedStorage.src

local dasar_states = {
	is_starting = false,
	is_started = false
}

--[=[
	Dasar acts like the header file for the entire Dasar framework.

]=]
local Dasar = {}

local function attempt_require(module, resolve, reject)
	local success, result = pcall(require, module)
	if success then
		resolve(result)
	else
		reject("Failed to require ModuleScript - " .. tostring(result))
	end

	return
end

local function loader_predicate(p_module)
	local r_module = Dasar._require(p_module):andThen(function(result)
		if result then
			return true
		end
	end)
end

local function resolve_module_from_path(module, module_path, start_dir, resolve, reject)
	local cur_dir = start_dir
	local count = module_path:GetNameCount()

	for i = 1, count do
		local name = module_path:GetName(i)
		local dir = cur_dir[name]

		if not dir then
			reject("Attempt to find module in non-existent directory: " .. tostring(name))
			return
		end

		if i == count then
			if dir:IsA("ModuleScript") then
				attempt_require(dir, resolve, reject)
			else
				reject("Module path does not point to a ModuleScript: " .. tostring(name))
			end
		else
			cur_dir = dir
		end
	end
end

--[=[
	```lua
	local Array = Dasar.Require("/core/variant/Array"):awaitValue()
	```
]=]
function Dasar._require(module: ModuleScript | string, start_dir: Instance?)
	return Promise.new(function(resolve, reject)
		if start_dir and start_dir ~= Instance then
			reject("start_dir must be an Instance")
			return
		end

		if typeof(module) == "Instance" and module:IsA("ModuleScript") then
			attempt_require(module, resolve, reject)
		end

		if typeof(module) == "string" then
			local module_path = ObjectPath(module)
			if not module_path then
				reject("Invalid module path: " .. tostring(module))
				return
			end

			if module_path:IsAbsolute() then
				resolve_module_from_path(module, module_path, dir_root, resolve, reject)
			else
				resolve_module_from_path(module, module_path, start_dir, resolve, reject)
			end
		end

		reject("Module must be a ModuleScript or a string")
	end)
end


function Dasar.Require(module: ModuleScript | string, start_dir: Instance)
	return Dasar._require(module, start_dir):awaitValue()
end

function Dasar.Start()
	return Promise.new(function()
		if dasar_states.is_started or dasar_states.is_starting then
			return
		end

		dasar_states.is_starting = true
		local start_time = tick()

		Provider.AwaitAllAssetsAsync()

		Loader.SpawnAll(
			Loader.LoadDescendants(dir_root),
			"_ready"
		)

		Loader.BindAll(
			Loader.LoadDescendants(dir_root),
			"_run",
			RunService.Heartbeat
		)

		dasar_states.is_starting = false
		dasar_states.is_started = true
	end)
end

return Dasar