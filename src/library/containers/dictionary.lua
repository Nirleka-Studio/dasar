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
	_size: number,
	_size_updt: boolean,
	_readonly: boolean
}

--[=[
	@within dictionary
	Returns a new dictionary object.
]=]
function dictionary.create(from: { [any]: any }?): Dictionary<any, any>
	local new_dict: Dictionary<any, any> = {
		_data = from or {},
		_size = 0,
		_size_updt = true,
		_readonly = false
	}

	return new_dict
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
function dictionary.find_key(dict: Dictionary<any, any>, value: any): any
	for k, v in pairs(dict._data) do
		if v == value then
			return k
		end
	end

	return nil
end

--[=[
	@within dictionary
	Returns the value associated with the key.
	Returns nil if no value is found.
]=]
function dictionary.get(dict: Dictionary<any, any>, key: any): any
	return dict._data[key]
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
	Returns true if the dictionary contains any keys.
	Returns false otherwise.
]=]
function dictionary.is_empty(dict: Dictionary<any, any>): boolean
	return dictionary.size(dict) == 0
end

--[=[
	@within dictionary
	Returns true if the dictionary is readonly.
	Returns false otherwise.
]=]
function dictionary.is_read_only(dict: Dictionary<any, any>): boolean
	return dict._readonly
end

--[=[
	@within dictionary
	Makes the dictionary readonly.
	Making any attempts to modify the dictionary will result in an error.
	However, any modifications of a table within the dictionary does not count.
]=]
function dictionary.make_read_only(dict: Dictionary<any, any>): ()
	-- idk about this one, should we give an error when we call make_read_only on a readonly dictionary?
	-- that technically counts as a modification, but the dictionary is already readonly.
	-- so idfk. Leave it like that.
	dict._readonly = true
end

--[=[
	@within dictionary
	Adds entries from `other` to `dict`.
	By default, duplicate keys are not copied over, unless `overwrite` is `true`.
]=]
function dictionary.merge(dict: Dictionary<any, any>, other: Dictionary<any, any>, overwrite: boolean): ()
	for k, v in pairs(other._data) do
		if not dict._data[k] or overwrite then
			dictionary.set(dict, k, v)
		end
	end
end

--[=[
	@within dictionary
	Sets the value associated with the key to the given value.
	Will return an error if the dictionary is readonly.
]=]
function dictionary.set(dict: Dictionary<any, any>, key: any, value: any): ()
	-- since im not fucking stupid and im not gonna write all of these checks
	-- on every methods that modifies a dictionary.
	if dict._readonly then
		error("Cannot modify a readonly dictionary.")
	end

	dict._data[key] = value
	dictionary._size_updt = true
end

--[=[
	@within dictionary
	Returns the number of keys in the dictionary.
	Dictionaries cache their size. If the dictionary is unmodified between calls, the cached size is returned.
]=]
function dictionary.size(dict: Dictionary<any, any>): number
	if dict._size_updt then
		local size = 0
		for _ in pairs(dict._data) do
			size += 1
		end
		dict._size = size
		dict._size_updt = false
	end

	return dict._size
end

return dictionary