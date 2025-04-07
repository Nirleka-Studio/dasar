-- Array.lua
-- NirlekaDev
-- February 14, 2025

local MurmurHash3 = require("../hash/hash_murmur3")

local hash_murmur3_one_32 = MurmurHash3.one_32
local hash_fmix32 = MurmurHash3.fmix32

local MAX_RECURSION = 15

local table = table
local type = type
local getmetatable = getmetatable
local string = string

local function neg_index(index, arr)
	local len = #arr

	if index < 0 then
		index = len + index + 1
	end

	if index < 1 or index > len then
		return nil
	end

	return index
end

--[=[
	@class Array

	--LEFT BLANK, PLEASE FILL IN
]=]
local Array = {}
Array.__index = Array

setmetatable(Array, {
	__call = function()
		return Array.new()
	end
})

function Array.new()
	return setmetatable({
		_data = {},
		_readonly = false,
		_hash_cache = nil,
		_hash_need_update = true
	}, Array)
end

function Array.fromTable(from: {})
end

function Array:__index(index)
	if Array[index] then
		return Array[index]
	else
		return self._data[index]
	end
end

function Array:__newindex(index, newValue)
	if self._readonly then
		error("Cannot modify a readonly Array!", 4)
	end

	if type(index) ~= "number" then
		error(string.format("Cannot index Array with type %s!", typeof(index)), 4)
	end

	if index > self:Size() then
		error("Index is out of bounds!", 4)
	end

	self._data[index] = newValue
end

function Array:__iter()
	return ipairs(self._data)
end

function Array:__len()
	return self:Size()
end

function Array.isArray(value)
	return type(value) == "table" and getmetatable(value) == Array
end

function Array:_recursive_hash(recursion_count)
	if recursion_count > MAX_RECURSION then
		ERR_THROW("Max recursion reached!")
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

function Array:_parse_changes()
	if self._readonly then
		error("Cannot modify a readonly Array!", 4)
	end

	self._hash_need_update = true
end

function Array:Clear()
	self:_parse_changes()

	table.clear(self._data)
end

function Array:Back()
	return self._data[#self._data]
end

function Array:Duplicate(deep: boolean, copies)
	local dict_copy = Array.new()
	copies = copies or {}

	if copies[self._data] then
		return copies[self._data]
	end

	copies[self._data] = dict_copy._data

	local function deepcopy(value)
		if not deep or type(value) ~= "table" then
			return value
		end

		if copies[value] then
			return copies[value]
		end

		local copy = {}
		copies[value] = copy

		for k, v in pairs(value) do
			copy[k] = deepcopy(v)
		end

		return copy
	end

	for key, value in pairs(self._data) do
		dict_copy._data[key] = deepcopy(value) -- Copy all values into new dictionary
	end

	return dict_copy
end

function Array:Erase(value: any)
	self:_parse_changes()
	local _, index = self:Has(value)
	if not index then
		return
	end

	table.remove(self._data, index)
end

function Array:Front()
	return self._data[1]
end

function Array:Find(value, from)
	from = from or 1

	if self:IsEmpty() or from > self:Size() then
		return nil
	end

	for i = from, self:Size() do
		if self._data[i] == value then
			return i
		end
	end

	return nil
end

function Array:Get(index: number)
	return self._data[index]
end

function Array:Has(value: any)
	if self:IsEmpty() then
		return false
	end

	return self:Find(value) ~= nil
end

function Array:Hash()
	if self._hash_need_update then
		local new_hash = self:recursive_hash(0)
		self._hash_cache = new_hash
		self._hash_need_update = false

		return new_hash
	else
		return self._hash_cache
	end
end

function Array:Insert(index: number, value: any)
	self:_parse_changes()

	if index then
		return table.insert(self._data, index, value)
	else
		return table.insert(self._data, value)
	end
end

function Array:IsReadOnly()
	return self._readonly == true
end

function Array:IsEmpty()
	return next(self._data) == nil
end

function Array:Set(index: number, value: any)
	self:_parse_changes()
	if not self._data[index] then
		return
	end

	self._data[index] = value
end

function Array:Size()
	return #self._data
end

function Array:MakeReadOnly()
	self._readonly = true
end

function Array:PickRandom()
	return self._data[math.random(1, self:Size())]
end

function Array:PushBack(value: any)
	self:_parse_changes()

	self._data[ #self._data + 1 ] = value
end

function Array:PushFront(value: any)
	self:_parse_changes()
	local data = self._data

	for i = #data, 1, -1 do
		data[i + 1] = data[i]
	end

	data[1] = value
end

function Array:Remove(index: number)
	self:_parse_changes()

	table.remove(self._data, index)
end

return Array