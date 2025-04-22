-- ObjectPath.lua
-- NirlekaDev
-- February 14, 2025

local Array = require("./Array")
local CharMap = require("./CharMap")

local table = table
local type = type

--[=[
	@class ObjectPath

	Represents a path string that can be used to access properties of an object.
	Based on Godot's NodePath.
]=]
local ObjectPath = {}
ObjectPath.__index = ObjectPath

setmetatable(ObjectPath, {
	__call = function(_, path)
		return ObjectPath._new(path)
	end
})

function ObjectPath.new(absolute: boolean, path: {}, subpath: {}, con_path: string, con_subpath: string, charmap)
	return setmetatable({
		_absolute = absolute,
		_charmap = charmap,
		_path = path,
		_subpath = subpath,
		_concatenated_path = con_path,
		_concatenated_subpath = con_subpath
	}, ObjectPath)
end

function ObjectPath._new(path: string)
	if ObjectPath.isObjectPath(path) then
		return path
	end

	local is_valid, reason = ObjectPath.isValidObjectPath(path)
	if not is_valid then
		error(reason, 4)
	end

	local path_charmap = CharMap(path)

	local parts = path_charmap:Split(":")

	local path_str = CharMap(parts[1])
	local subpaths = {}
	for i = 2, #parts do
		table.insert(subpaths, parts[i])
	end

	local is_absolute = path_str[1] == "/"

	local path_segments = path_str:Split("/")

	local subpath_segments = {}
	for _, s in ipairs(subpaths) do
		local split_sub = CharMap(s):Split("/")
		for _, seg in ipairs(split_sub) do
			table.insert(subpath_segments, seg)
		end
	end

	return ObjectPath.new(
		is_absolute,
		Array(path_segments),
		Array(subpath_segments),
		table.concat(path_segments, "/"),
		table.concat(subpath_segments, ":"),
		path_charmap
	)
end

function ObjectPath:__tostring()
	return self._charmap:ToString()
end

--[=[
	Returns true if the given path is a valid ObjectPath, false otherwise.
	Note that this is only for strings.

	```lua
	local isValid, reason = ObjectPath.isValidObjectPath(":ObjectPath:Subpath")
	print(isValid, reason) -- false, Path must not start or end with ':'

	print(ObjectPath.isValidObjectPath("ObjectPath:Subpath")) -- true
	print(ObjectPath.isValidObjectPath("/ObjectPath:Subpath")) -- true
	print(ObjectPath.isValidObjectPath("//ObjectPath:Subpath")) -- false
	print(ObjectPath.isValidObjectPath("ObjectPath::Subpath")) -- fase
	```
]=]
function ObjectPath.isValidObjectPath(path: string)
	if type(path) ~= "string" then
		return false, "Path must be a string"
	end

	if path:sub(1, 1) == ":" or path:sub(-1, -1) == ":" then
		return false, "Path must not start or end with ':'"
	end

	if path:find("::") then
		return false, "Path must not contain empty subpaths (::)"
	end

	for subpath in path:gmatch("[^:]+") do
		if subpath:find("//") then
			return false, "Subpath contains empty segment (//)"
		end
	end

	return true
end

--[=[
	Returns true if the given value is an ObjectPath instance.

	```lua
	local path = ObjectPath("ObjectPath:Subpath")

	print(ObjectPath.isObjectPath(path)) -- true
	print(ObjectPath.isObjectPath("ObjectPath:Subpath")) -- false
	```
]=]
function ObjectPath.isObjectPath(value)
	return getmetatable(value) == ObjectPath
end

--[=[
	Returns a string of the path delimited by "/"

	```lua
	local path = ObjectPath("/path/to/object:Position:X")

	print(path:GetPath()) -- "/path/to/object"
	```
]=]
function ObjectPath:GetConcatenatedNames()
	return self._concatenated_path
end

--[=[
	Returns a string of the path delimited by ":"

	```lua
	local path = ObjectPath("/path/to/object:Position:X")

	print(path:GetSubpath()) -- "Position:X"
	```
]=]
function ObjectPath:GetConcatenatedSubnames()
	return self._concatenated_subpath
end

--[=[
	Returns the indexed path with the delimiter "/".

	```lua
	local path = ObjectPath("/path/to/object:Position:X")
	print(path:GetName(1)) -- "path"
	print(path:GetName(2)) -- "to"
	print(path:GetName(3)) -- "object"
	print(path:GetName(4)) -- nil
	```
]=]
function ObjectPath:GetName(index: number)
	return self._path[index]
end

--[=[
	Returns the amount of path delimited in "/".

	```lua
	local path = ObjectPath("/path/to/object:Position:X")
	print(path:GetNameCount()) -- 3
	```
]=]
function ObjectPath:GetNameCount()
	return self._path:Size()
end

--[=[
	Returns the indexed path with the delimiter ":".

	```lua
	local path = ObjectPath("/path/to/object:Position:X")
	print(path:GetName(1)) -- "Position"
	print(path:GetName(2)) -- "X"
	print(path:GetName(3)) -- nil
	```
]=]
function ObjectPath:GetSubname(index: number)
	return self._subpath[index]
end

--[=[
	Returns the amount of path delimited in ":".

	```lua
	local path = ObjectPath("/path/to/object:Position:X")
	print(path:GetNameCount()) -- 2
	```
]=]
function ObjectPath:GetSubnameCount()
	return self._subpath:Size()
end

--[=[
	Returns true if the path is an obsolute path.
	Absolute paths always starts with "/".

	```lua
	local path = ObjectPath("/path/to/object:Position:X")
	print(path:IsAbsolute()) -- true
	```
]=]
function ObjectPath:IsAbsolute()
	return self._absolute == true
end

return ObjectPath
