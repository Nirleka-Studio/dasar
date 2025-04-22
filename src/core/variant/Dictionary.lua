-- Dictionary.lua
-- NirlekaDev
-- March 22, 2025

local MurmurHash3 = require("../hash/hash_murmur3")

local hash_murmur3_one_32 = MurmurHash3.one_32
local hash_fmix32 = MurmurHash3.fmix32

local MAX_RECURSION = 15

local type = type
local next = next
local getmetatable = getmetatable
local setmetatable = setmetatable
local table = table

--[=[
	@class Dictionary

	Wraps around the table to provide a more convenient API for dictionary-like data structures.
]=]
local Dictionary = {}
Dictionary.__index = Dictionary

setmetatable(Dictionary, {
	__call = function(_, value)
		return Dictionary._new(value)
	end
})

function Dictionary.new()
	return setmetatable({
		_data = {},
		_readonly = false,
		_size_cache = 0,
		_hash_cache = 0,
		_hash_need_update = true,
		_size_need_update = true
	}, Dictionary)
end

function Dictionary._new(value)
	return Dictionary.toDictionary(value)
end

function Dictionary.fromTable(from: {})
	local dict_copy = Dictionary.new()

	for i, v in pairs(from) do
		dict_copy[i] = v
	end

	return dict_copy
end

function Dictionary:__index(index)
	if Dictionary[index] then
		return Dictionary[index]
	else
		return self._data[index]
	end
end

function Dictionary:__newindex(index, new_value)
	if Dictionary[index] then
		rawset(self, index, new_value)

		return
	end

	self:Set(index, new_value)
end

function Dictionary:__iter()
	return pairs(self._data)
end

function Dictionary:__len()
	return self:Size()
end

function Dictionary.isDictionary(value)
	return getmetatable(value) == Dictionary
end

function Dictionary.toDictionary(dict)
	if dict == nil then
		dict = Dictionary.new()
	end

	if Dictionary.isDictionary(dict) then
		return dict
	end

	return Dictionary.fromTable(dict)
end

function Dictionary:_recursive_hash(recursion_count)
	if recursion_count > MAX_RECURSION then
		error("Max recursion reached!", 4)
	end

	local h = hash_murmur3_one_32(1)
	recursion_count = recursion_count + 1

	for key, value in pairs(self._data) do
		local keyHash = hash_murmur3_one_32(tostring(key):len(), h)
		local valueHash = hash_murmur3_one_32(tostring(value):len(), h)

		h = hash_murmur3_one_32(keyHash, h)
		h = hash_murmur3_one_32(valueHash, h)
	end

	return hash_fmix32(h)
end

function Dictionary:Clear()
	for i, _ in pairs(self._data) do
		self:Set(i, nil)
	end
end

function Dictionary:Duplicate(deep: boolean)
	local new_dict = Dictionary.new()

	if not deep then

		for i, v in ipairs(self._data) do
			new_dict._data[i] = v
		end

		return new_dict
	end

	local stack = {}
	local copy = {}
	new_dict[self._data] = copy
	table.insert(stack, {src = self._data, dst = copy})

	while #stack > 0 do
		local current = table.remove(stack)
		local src = current.src
		local dst = current.dst

		for k, v in pairs(src) do
			local copy_k = (type(k) == "table") and (new_dict[k] or {}) or k
			if type(k) == "table" and not new_dict[k] then
				new_dict[k] = copy_k
				table.insert(stack, {src = k, dst = copy_k})
			end

			if type(v) == "table" then
				if not new_dict[v] then
					new_dict[v] = {}
					table.insert(stack, {src = v, dst = new_dict[v]})
				end
				dst[copy_k] = new_dict[v]
			else
				dst[copy_k] = v
			end
		end
	end
end

function Dictionary:Erase(key: any)
	self:Set(key, nil)
end

function Dictionary:FindKey(value: any)
	for i, k in pairs(self._data) do
		if k == value then
			return i
		end
	end

	return nil
end

function Dictionary:Get(key: any, default: any)
	return self._data[key] or default
end

function Dictionary:GetOrAdd(key: any, default: any)
	local value = self._data[key]
	if value == nil and default ~= nil then
		self._data[key] = default
		return default
	end

	return value
end

function Dictionary:Has(key: any)
	return self._data[key] ~= nil
end

function Dictionary:HasAll(keys: { any })
	for key, _ in ipairs(keys) do
		if self._data[key] == nil then
			return false
		end
	end
	return true
end

function Dictionary:Hash()
	if self._hash_need_update then
		local new_hash = self:_recursive_hash(0)
		self._hash_cache = new_hash
		self._hash_need_update = false

		return new_hash
	else
		return self._hash_cache
	end
end

function Dictionary:IsEmpty()
	return next(self._data) == nil
end

function Dictionary:IsReadOnly()
	return self._readonly == true
end

function Dictionary:Keys()
	local keys = {}
	for i, _ in pairs(self._data) do
		table.insert(keys, i)
	end

	return keys
end

function Dictionary:MakeReadOnly()
	self._readonly = true
end

function Dictionary:Set(key: any, value: any)
	if self._readonly then
		error("Cannot modify a readonly Dictionary!", 4)
	end

	self._size_need_update = true
	self._hash_need_update = true
	self._data[key] = value
end

function Dictionary:Size()
	if self._size_need_update then
		local count = 0
		for _ in pairs(self._data) do
			count += 1
		end

		self._size_cache = count
		self._size_need_update = false

		return count
	else
		return self._size_cache
	end
end

function Dictionary:Merge(dictionary: { [any] : any}, overwrite: boolean)
	dictionary = Dictionary.toDictionary(dictionary)

	for key, value in pairs(dictionary) do
		if self._data[key] == nil or overwrite then
			self:Set(key, value)
		end
	end
end

function Dictionary:Merged(dictionary: { [any] : any}, overwrite: boolean)
	local dict_copy = Dictionary.new()
	for key, value in pairs(self._data) do
		dict_copy._data[key] = value
	end

	for key, value in pairs(dictionary) do
		if dict_copy._data[key] == nil or overwrite then
			dict_copy._data[key] = value
		end
	end

	return dict_copy
end

function Dictionary:Values()
	local values = {}
	for _, v in pairs(self._data) do
		table.insert(values, v)
	end

	return values
end

return Dictionary