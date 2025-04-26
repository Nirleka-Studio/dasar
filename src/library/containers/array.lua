-- array.lua
-- NirlekaDev
-- April 26, 2025

local error = error
local type = type
local table = table
local clear = table.clear
local find = table.find
local remove = table.remove
local math = math
local floor = math.floor
local string = string
local format = string.format
local typeof = typeof

--[=[
	@class array
]=]
local array = {}

--[=[
	@within array
]=]
export type Data = { [number] : any }

--[=[
	@within array
]=]
export type Array = {
	_data: { [number] : any },
	_readonly: boolean,
	_size: number,
	_size_updt: boolean
}

--[=[
	@within array
	Returns a new array.
]=]
function array.create(from: Data?)
	local new_array: Array = {
		_data = from or {},
		_readonly = false,
		_size = 0,
		_size_updt = true
	}

	return new_array
end

--[=[
	@within array
	Removes all element from the array.
]=]
function array.clear(arr: Array)
	-- no... ive broken the code... every checks shall be in .set() goddamit!!!
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	-- but oh well. we need you anyway.
	clear(arr._data)
	arr._size = 0
	arr._size_updt = false
end

--[=[
	@within array
	Removes the first occurence of index assosicated with `value`
]=]
function array.erase(arr: Array, value: any)
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	local index = array.find(arr, value)
	if not index then
		return
	end

	remove(arr._data, index)
	arr._size_updt = true
end

--[=[
	@within array
	Returns the index of the first occurence of `value`
]=]
function array.find(arr: Array, value: any, from: number?): number?
	return find(arr._data, value, from)
end

--[=[
	@within array
	Returns the value of `index`
	Shorthand for array._data[index]
]=]
function array.get(arr: Array, index: number): any
	return arr._data[index]
end

--[=[
	@within array
	Returns true if the array contains `value`
]=]
function array.has(arr: Array, value: any): boolean
	return array.find(arr, value) ~= nil
end

--[=[
	@within array
	Returns true if the array is empty, meaning no entries.
]=]
function array.is_empty(arr: Array): boolean
	return array.size(arr) == 0
end

--[=[
	@within array
	Inserts a new index with `value` at the end of the array.
]=]
function array.push_back(arr: Array, value: any)
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	arr._data[ array.size(arr) + 1 ] = value
	arr._size_updt = true
end

--[=[
	@within array
	Removes an existing index from the array.
	Maintains the order of the array.
]=]
function array.remove_at(arr: Array, index: number)
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end
	arr._size_updt = true
	return remove(arr._data, index)
end

--[=[
	@within array
	Sets the value of `index` to `value`
]=]
function array.set(arr: Array, index: number, value: any)
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	if type(index) ~= "number" then
		error(format("Cannot index Array with type %s", typeof(index)), 4)
	end

	local size = array.size(arr)

	if index ~= floor(index) then
		error("Array indices must be integers", 4)
	end

	if index > (size + 1) then
		error("Index is out of bounds", 4)
	end

	if value == nil then
		remove(arr._data, index)
		arr._size_updt = true
		return
	end

	if index > size then
		arr._size += 1
		arr._size_updt = false
	end

	arr._data[index] = value
end

--[=[
	@within array
	Returns the size of the array.
	Sizes of arrays and cached in the `_size` field.
]=]
function array.size(arr: Array): number
	return arr._size
end

return array