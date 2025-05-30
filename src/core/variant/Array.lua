-- Array.lua
-- NirlekaDev
-- February 14, 2025

local MurmurHash3 = require("../hash/hash_murmur3")

local hash_murmur3_one_32 = MurmurHash3.one_32
local hash_fmix32 = MurmurHash3.fmix32

local MAX_RECURSION = 15

local type = type
local next = next
local getmetatable = getmetatable
local setmetatable = setmetatable
local table = table

local function neg_index(index, arr)
	if type(index) ~= "number" then
		return index
	end

	if index >= 0 then
		return index
	end

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

	Wraps around a table to provide a more convenient API for array-like data structures.
	Enforces the use of 1-based indexing and provides a variety of utility methods.
]=]
local Array = {}
Array.__index = Array

setmetatable(Array, {
	__call = function(_, ...)
		return Array._new(...)
	end
})

function Array.new()
	return setmetatable({
		_data = {},
		_readonly = false,
		_hash_cache = 0,
		_hash_need_update = true
	}, Array)
end

function Array._new(value)
	if type(value) == "table" then
		return Array.fromTable(value)
	end

	return Array.new()
end

function Array.fromTable(from: { [number]: any })
	local newArray = Array.new()

	for _, v in ipairs(from) do
		newArray:PushBack(v)
	end

	return newArray
end

function Array.ref(from: { [number]: any })
	local newArray = Array.new()
	newArray._data = from
	return newArray
end

function Array:__index(index)
	index = neg_index(index, self._data)

	if Array[index] then
		return Array[index]
	else
		return self._data[index]
	end
end

function Array:__newindex(index, new_value)
	if Array[index] then
		rawset(self, index, new_value)

		return
	end

	self:Set(index, new_value)
end

function Array:__iter()
	return ipairs(self._data)
end

function Array:__len()
	return self:Size()
end

function Array.isArray(value: any)
	return type(value) == "table" and getmetatable(value) == Array
end

function Array:_recursive_hash(recursion_count)
	if recursion_count > MAX_RECURSION then
		error("Max recursion reached!", 4)
	end

	local h = hash_murmur3_one_32(1)
	recursion_count = recursion_count + 1

	for key, value in ipairs(self._data) do
		local keyHash = hash_murmur3_one_32(tostring(key):len(), h)
		local valueHash = hash_murmur3_one_32(tostring(value):len(), h)

		h = hash_murmur3_one_32(keyHash, h)
		h = hash_murmur3_one_32(valueHash, h)
	end

	return hash_fmix32(h)
end

function Array:Append(value: any)
	return self:PushBack(value)
end

function Array:AppendArray(array: { [number]: any })
	array = Array(array)

	if not array then
		return
	end

	if array:IsEmpty() then
		return
	end

	for _, v in ipairs(array) do
		self:PushBack(v)
	end
end

function Array:Clear()
	for k, _ in ipairs(self._data) do
		self:Set(k, nil)
	end
end

function Array:Back()
	return self._data[#self._data]
end

function Array:Duplicate(deep: boolean)
	local new_arr = Array.new()

	if not deep then

		for i, v in ipairs(self._data) do
			new_arr._data[i] = v
		end

		return new_arr
	end

	local stack = {}
	local copy = {}
	new_arr[self._data] = copy
	table.insert(stack, {src = self._data, dst = copy})

	while #stack > 0 do
		local current = table.remove(stack)
		local src = current.src
		local dst = current.dst

		for k, v in pairs(src) do
			local copy_k = (type(k) == "table") and (new_arr[k] or {}) or k
			if type(k) == "table" and not new_arr[k] then
				new_arr[k] = copy_k
				table.insert(stack, {src = k, dst = copy_k})
			end

			if type(v) == "table" then
				if not new_arr[v] then
					new_arr[v] = {}
					table.insert(stack, {src = v, dst = new_arr[v]})
				end
				dst[copy_k] = new_arr[v]
			else
				dst[copy_k] = v
			end
		end
	end

	return new_arr
end

function Array:Erase(value: any)
	local index = self:Find(value)
	if not index then
		return
	end

	self:Set(index, nil)
end

function Array:Front()
	return self._data[1]
end

function Array:Find(value: any, from: number)
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
	index = neg_index(index, self._data)
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
		local new_hash = self:_recursive_hash(0)
		self._hash_cache = new_hash
		self._hash_need_update = false

		return new_hash
	else
		return self._hash_cache
	end
end

function Array:IsReadOnly()
	return self._readonly == true
end

function Array:IsEmpty()
	return next(self._data) == nil
end

function Array:Set(index: number, value: any)
	if self._readonly then
		error("Cannot modify a readonly Array!", 4)
	end

	index = neg_index(index, self._data)

	if type(index) ~= "number" then
		error(string.format("Cannot index Array with type %s!", typeof(index)), 4)
	end

	if index ~= math.floor(index) then
		error("Array indices must be integers!", 4)
	end

	if index > (self:Size() + 1) then
		error("Index is out of bounds!", 4)
	end

	if value == nil then
		table.remove(self._data, index)
		self._hash_need_update = true
		return
	end

	self._data[index] = value

	self._hash_need_update = true
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
	self:Set(self:Size() + 1, value)
end

function Array:PushFront(value: any)
	for i = self:Size(), 1, -1 do
		self:Set(i + 1, self._data[i])
	end

	self:Set(1, value)
end

function Array:Remove(index: number)
	return self:Set(index, nil)
end

return Array