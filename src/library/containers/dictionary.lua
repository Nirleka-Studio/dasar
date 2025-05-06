-- dictionary.lua
-- NirlekaDev
-- April 26, 2025

--!strict

local array = require("./array")

--[=[
	@class dictionary
]=]
local dictionary = {}

--[=[
	@within dictionary
]=]
export type Dictionary<K, V> = {
	_data: { [K]: V },
	_size: number
}

--[=[
	@within dictionary
	Returns a new dictionary object.
]=]
function dictionary.create<K, V>(from: { [K]: V }?): Dictionary<K, V>
	local new_dict: Dictionary<K, V> = {
		_data = from or {},
		_size = if from then dictionary.count(from) else 0
	}

	return new_dict
end

--[=[
	@within dictionary
	Manually counts all the entries in the table and returns the total count.
]=]
function dictionary.count<K, V>(haystack: { [K]: V }): number
	local size = 0
	for _ in pairs(haystack) do
		size += 1
	end
	return size
end

--[=[
	@within dictionary
	Sets the the value assosciated with the key to nil.
]=]
function dictionary.erase(dict: Dictionary<any, any>, key: any): ()
	dictionary.set(dict, key, nil)
end

--[=[
	@within dictionary
	Returns the first key assosciated with the value.
	Returns nil if no key is found.
]=]
function dictionary.find_key<K, V>(dict: Dictionary<K, V>, value: V): K?
	for k, v in pairs(dict._data) do
		if v :: any == value :: any then -- some shit to make the type checker stfu
			return k
		end
	end

	return nil
end

--[=[
	@within dictionary
	Returns the value associated with the key.
	If the value is nil, returns `default`
]=]
function dictionary.get<K, V>(dict: Dictionary<K, V>, key: K, default: any?): V
	local value = dict._data[key]
	return if value then value else default
end

--[=[
	@within dictionary
	Returns true if the dictionary contains the key.
	Returns false otherwise.
]=]
function dictionary.has(dict: Dictionary<any, any>, key: any): boolean
	return dict._data[key] ~= nil
end

--[=[
	@within dictionary
	Returns true if the dictionary contains all the keys from the given Array.
	Returns false otherwise.
]=]
function dictionary.has_all(dict: Dictionary<any, any>, keys: array.Array<any>): boolean
	for _, key in ipairs(keys._data) do
		if not dict._data[key] then
			return false
		end
	end

	return true
end

--[=[
	@within dictionary
	Returns an iterator function that iterates through the dictionary.
]=]
function dictionary.iter<K, V>(dict: Dictionary<K, V>): (({ [K]: V }, K?) -> (K?, V), { [K]: V }, nil)
	-- this is a very weird and shit type annotation, ill give you that
	return pairs(dict._data)
end

--[=[
	@within dictionary
	Returns true if the dictionary contains any keys.
	Returns false otherwise.
]=]
function dictionary.is_empty<K, V>(dict: Dictionary<K, V>): boolean
	return dict._size == 0
end

--[=[
	@within dictionary
	Adds entries from `other` to `dict`.
	By default, duplicate keys are not copied over, unless `overwrite` is `true`.
]=]
function dictionary.merge<K, V>(dict: Dictionary<K, V>, other: Dictionary<K, V>, overwrite: boolean): ()
	for k, v in pairs(other._data) do
		if not dict._data[k] :: boolean or overwrite then
			dictionary.set(dict, k, v)
		end
	end
end

--[=[
	@within dictionary
	Sets the value associated with the key to the given value.
]=]
function dictionary.set<K, V>(dict: Dictionary<K, V>, key: K, value: V): ()
	--[[
		"TypeError: Type function instance union<V, nil> depends on generic function parameters
			but does not appear in the function signature; this construct cannot be type-checked at this time"
		BRO STFU
	]]
	local exists = (dict._data[key] :: any ~= nil)
	local is_deletion= value :: any == nil

	-- yes. i need to EXPLICITLY ASSERT THAT THESE, ARE, INFACT, BOOLEANS.
	-- AND NO, EVEN IF I DID ASSERT THE TYPE ON THE 2 VARIABLES BEING COMPARED, IT WONT STFU
	if not exists :: boolean and not is_deletion :: boolean then
		dict._size += 1
	elseif exists :: boolean and is_deletion :: boolean then
		dict._size -= 1
	end

	dict._data[key] = value
end

--[=[
	@within dictionary
	Returns the number of entries in the dictionary.
]=]
function dictionary.size<K, V>(dict: Dictionary<K, V>): number
	return dict._size
end

return dictionary