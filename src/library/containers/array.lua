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
export type Array<T> = {
	_data: { [number]: T },
	_readonly: boolean
}

--[=[
	@within array
	Returns a new array.
]=]
function array.create(from: { [number]: any }?)
	local new_array: Array<any> = {
		_data = from or {},
		_readonly = false
	}

	return new_array
end

--[=[
	@within array
	Adds the elements of from `fruits` to the end of `basket`
]=]
function array.append_array(basket: Array<any>, fruits: Array<any>)
	for _, fruit in ipairs(fruits._data) do
		array.push_back(basket, fruit)
	end
end

--[=[
	@within array
	Returns a new array with the elements of `fruits` on the end of `basket`
]=]
function array.concat_array(basket: Array<any>, fruits: Array<any>): Array<any>
	local new_basket: Array<any> = array.duplicate(basket)

	for _, fruit in ipairs(fruits._data) do
		array.push_back(new_basket, fruit)
	end

	return new_basket
end

--[=[
	@within array
	Removes all element from the array.
]=]
function array.clear(arr: Array<any>)
	-- no... ive broken the code... every checks shall be in .set() goddamit!!!
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	-- but oh well. we need you anyway.
	clear(arr._data)
end

--[=[
	@within array
	Removes the first occurence of index assosicated with `value`
]=]
function array.erase(arr: Array<any>, value: any)
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	local index = array.find(arr, value)
	if not index then
		return
	end

	remove(arr._data, index)
end

--[=[
	@within array
	Returns a shallow copy of `arr`
]=]
function array.duplicate(arr: Array<any>): Array<any>
	return array.create(table.clone(arr._data))
end

--[=[
	@within array
	Returns the index of the first occurence of `value`
]=]
function array.find(arr: Array<any>, value: any, from: number?): number?
	return find(arr._data, value, from)
end

--[=[
	@within array
	Returns the value of `index`
	Shorthand for array._data[index]
]=]
function array.get(arr: Array<any>, index: number): any
	return arr._data[index]
end

--[=[
	@within array
	Returns true if the array contains `value`
]=]
function array.has(arr: Array<any>, value: any): boolean
	return array.find(arr, value) ~= nil
end

--[=[
	@within array
	Returns true if the array is empty, meaning no entries.
]=]
function array.is_empty(arr: Array<any>): boolean
	return #arr._data == 0
end

--[=[
	@within array
	Returns true if the array's `_readonly` is true.
]=]
function array.is_readonly(arr: Array<any>): boolean
	return arr._readonly
end

--[=[
	@within array
	Returns an interator function to iterate over the array.
]=]
function array.iter(arr: Array<any>): () -> (number, any)
	local i = 0
	return function()
		i = i + 1
		if i <= #arr._data then
			return i, arr._data[i]
		end

		return
	end
end

--[=[
	@within array
	Makes the array read-only.
]=]
function array.make_readonly(arr: Array<any>)
	arr._readonly = true
end

--[=[
	@within array
	Inserts a new index with `value` at the end of the array.
]=]
function array.push_back(arr: Array<any>, value: any)
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	arr._data[ #arr._data + 1 ] = value
end

--[=[
	@within array
	Removes an existing index from the array.
	Maintains the order of the array.
]=]
function array.remove_at(arr: Array<any>, index: number)
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	return remove(arr._data, index)
end

--[=[
	@within array
	Sets the value of `index` to `value`
]=]
function array.set(arr: Array<any>, index: number, value: any)
	if arr._readonly then
		error("Cannot modify a readonly Array", 4)
	end

	if type(index) ~= "number" then
		error(format("Cannot index Array with type %s", typeof(index)), 4)
	end

	local size = #arr._data

	if index ~= floor(index) then
		error("Array indices must be integers", 4)
	end

	if index > (size + 1) then
		error("Index is out of bounds", 4)
	end

	if value == nil then
		remove(arr._data, index)
		return
	end

	arr._data[index] = value
end

--[=[
	@within array
	Returns the size of the array.
	Sizes of arrays and cached in the `_size` field.
]=]
function array.size(arr: Array<any>): number
	return #arr._data
end

return array
