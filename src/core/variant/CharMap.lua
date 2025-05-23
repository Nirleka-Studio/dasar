-- CharMap.lua
-- NirlekaDev
-- March 30, 2025 // Idul Fitr!!

--[=[
	@class CharMap

	Represent and manipulate a string in a more structured way
	with additional methods.
	Lacks type and error handling for performance purposes.
]=]
local CharMap = {}
CharMap.__index = CharMap

setmetatable(CharMap, {
	__call = function(_, value)
		return CharMap._new(value)
	end
})

function CharMap.new(text: string)
	local self = setmetatable({}, CharMap)

	self._string = text or ""
	self._map = self:Explode()

	return self
end

function CharMap._new(value)
	if type(value) ~= "string" then
		return nil
	end

	if CharMap.IsCharMap(value) then
		return value
	end

	return CharMap.new(value)
end

function CharMap:__index(index)
	if CharMap[index] then
		return CharMap[index]
	elseif type(index) == "number" and self._map[index] then
		return self._map[index]
	elseif type(self._string[index]) == "function" then
		--[[
			This is pretty hacky. As if we do shit like `print(CharMap:upper())` as upper() is part
			of the lua string library, it wont work shit as the goddamn `:` operator fucks everything
			up by passing `self` as the first parameter to the function.
		]]
		return function(_, ...)
			return self._string[index](self._string, ...)
		end
	else
		return self._string[index]
	end
end

function CharMap:__add(value)
	return self:Concat(value)
end

function CharMap:__concat(value)
	return self:Concat(value)
end

function CharMap:__eq(value)
	return self:IsEqualTo(value)
end

function CharMap:__iter()
	return ipairs(self._map)
end

function CharMap:__tostring()
	return self:ToString()
end

function CharMap:__len()
	return self:Length()
end

function CharMap:__lt(value)
	return self:CompareRight(value)
end

function CharMap:__le(value)
	return self:CompareEqualRight(value)
end

--[=[
	Returns true if the given value is a CharMap instance.
]=]
function CharMap.IsCharMap(value)
	return getmetatable(value) == CharMap
end

--[=[
	Returns an array of strings between the given `opening` and `closing` strings.

	```lua
	local text = CharMap("Hello [world] and [universe]")
	local results = text:Between("[", "]")
	print(results) -- {"world", "universe"}
	```
]=]
function CharMap:Between(opening: string, closing: string)
	--[[
		Oh god.
		This is a jumbled mess of a function made by me.
	]]
	local results = {}
	local i = 1
	local text = self._string
	local len = #text

	while i <= len do
		local start = string.find(text, opening, i, true)
		if not start then break end

		local level = 1
		local j = start + string.len(opening)
		local contentStart = j

		while j <= len and level > 0 do
			local nextOpen = string.find(text, opening, j, true)
			local nextClose = string.find(text, closing, j, true)

			if nextClose and (not nextOpen or nextClose < nextOpen) then
				level = level - 1
				if level == 0 then

					local content = string.sub(text, contentStart, nextClose - 1)
					table.insert(results, content)
				end
				j = nextClose + string.len(closing)
			elseif nextOpen then
				level = level + 1
				j = nextOpen + string.len(opening)
			else
				break
			end
		end

		i = (start + 1)
	end

	return results
end

--[=[
	Returns true if the string begins with the given `text`.
	See also `CharMap:EndsWith()`.
]=]
function CharMap:BeginsWith(text: string)
	if #text > #self._string then
		return false
	end

	for i = 1, #text do
		if self._string:sub(i, i) ~= text:sub(i, i) then
			return false
		end
	end

	return true
end

--[=[
	Returns true if the string comes before `right` in lexicographical order.
	Compares strings character by character based on their ASCII (or UTF-8) values.
	This can also be done with the `<` operator.
]=]
function CharMap:CompareRight(right)
	if type(right) == "string" then
		return self._string < right
	elseif type(right) == "table" and CharMap.IsCharMap(right) then
		return self._string < right._string
	end

	return nil
end

--[=[
	Functions just like `CharMap:CompareRight(right)`
	This can also be done with the `<=` operator.
]=]
function CharMap:CompareEqualRight(right)
	if type(right) == "string" then
		return self._string <= right
	elseif type(right) == "table" and CharMap.IsCharMap(right) then
		return self._string <= right._string
	end

	return nil
end

--[=[
	Returns the combined string if the value is a string.
	Returns a new CharMap instance with the combined string if the value is a CharMap.
	This can also be done with the `+` and `..` operators.
]=]
function CharMap:Concat(value)
	if type(value) == "string" then
		return self._string .. value
	elseif type(value) == "table" and CharMap.IsCharMap(value) then
		return CharMap.new(self._string .. value._string)
	end

	return nil
end

--[=[
	Returns a new CharMap instance with the same string.
]=]
function CharMap:Duplicate()
	return CharMap.new(self._string)
end

--[=[
	Returns true if the string ends with the given `text`.
	See also `CharMap:BeginsWith()`.
]=]
function CharMap:EndsWith(text: string)
	if #text > #self._string then
		return false
	end

	local selfLen = #self._string
	local textLen = #text

	for i = 0, textLen - 1 do
		if self._string:sub(selfLen - i, selfLen - i) ~= text:sub(textLen - i, textLen - i) then
			return false
		end
	end

	return true
end

--[=[
	Splits the string into an array of individual characters.
]=]
function CharMap:Explode()
	if self._map then
		return self._map
	end
	local characters = {}

	for i = 1, #self._string do
		characters[i] = self._string:sub(i,i)
	end

	return characters
end

--[=[
	Splits the string into an array of individual characters,
	wrapping each in instances of the provided class.
]=]
function CharMap:ExplodeToClass(func)
	local characters = {}

	for i = 1, #self._string do
		characters[i] = func(self._string:sub(i,i))
	end

	return characters
end

--[=[
	Returns a new CharMap of the formatted string by replacing all occurrences
	of `placeholder` with the corresponding values.

	The placeholder must always have an underscore to separate the opening and closing.
	Such as "{_}", and "_}" or "{_" are invalid. If a placeholder is invalid, the function
	will replace the placeholders in the CharMap with the order of the given values.

	If theres no occurences, it will simply return the original CharMap.

	```lua
	local text = CharMap("Hello there {1} and {2}!")
	local formatted = text:Format({
		"world",
		"universe"
	})

	print(formatted) -- "Hello there world and universe!"

	local text = CharMap("Hello there {player} and {pet}!")
	local formatted = text:Format({
		pet = "dog",
		player = "Nirleka"
	})

	print(formatted) -- "Hello there Nirleka and dog!"
	```
]=]
function CharMap:Format(values: { [string | number]: any }, placeholder: string)
	-- O(sobbing miserably)

	placeholder = placeholder or "{_}"
	local formatted: string = self._string
	local opening, closing = placeholder:match("(.-)_(.*)")
	local always_use_order = false
	if not opening or not closing then
		always_use_order = true
	end
	local occurrences: { [number] : string } = self:Between(opening, closing)
	if not occurrences or #occurrences == 0 then
		return self
	end

	local numeric_placeholders_used = {}

	for key, value in pairs(values) do
		local str_value = tostring(value)

		if type(key) == "number" or always_use_order then
			-- for any numbers, or always_use_order is true,
			-- just replace the placeholders by order
			if key <= #occurrences and not numeric_placeholders_used[key] then
				local placeholder_content = occurrences[key]
				local to_replace = opening .. placeholder_content .. closing
				formatted = formatted:gsub(to_replace, str_value, 1)
				numeric_placeholders_used[key] = true
			end
		elseif type(key) == "string" then
			-- for string keys, replace ALL occurrences with that name
			local str_key = tostring(key)
			local to_replace = opening .. str_key .. closing
			formatted = formatted:gsub(to_replace, str_value)
		end
	end

	return CharMap.new(formatted)
end

--[=[
	Returns true if the string does not have any characters.
]=]
function CharMap:IsEmpty()
	return next(self._map) == nil
end

--[=[
	Returns true if the two strings have the exact same character sequence.
	This also can be performed with the `==` operator.
]=]
function CharMap:IsEqualTo(value)
	if type(value) == "string" then
		return self._string == value
	elseif type(value) == "table" and self:IsCharMap(value) then
		return self._string == value._string
	end

	return false
end

--[=[
	Returns the amount of characters inside the string.
	This includes whitespaces.
	This also can be performed with the `#` operator.
]=]
function CharMap:Length()
	return #self._string
end

--[=[
	Returns the last string before the delimeter.

	```lua
	local text = CharMap("/path/to/resource")
	print(path:LastDelim("/")) -- "resource"
	```
]=]
function CharMap:LastDelim(delimeter: string)
	local escaped = delimeter:gsub("(%p)", "%%%1")
	local lastSeparator = self._string:match(".*" .. escaped .. "()")

	if lastSeparator then
		return CharMap.new(self._string:sub(lastSeparator))
	else
		return self
	end
end

--[=[
	Normalizes the string URL by removing redundant slashes
	while preserving the protocol format and ensuring
	it ends with a single trailing slash.

	```lua
	local url = CharMap("https://example.com//path//to//resource")
	print(url:UrlNormalize()) -- "https://example.com/path/to/resource/"
	```
]=]
function CharMap:UrlNormalize(trailing_slash: boolean)
	local protocol, rest = self._string:match("^([%a][%w+.-]*:)(.*)")

	if not protocol then
		rest = self._string
		protocol = ""
	end

	if protocol ~= "" then
		rest = rest:gsub("^/*", "")
		protocol = protocol .. "//"
	end

	rest = rest:gsub("//+", "/")

	-- turns out, github is very sensitive to URL.
	-- so if we add a trailing slash it will fuck us up royally.
	if not rest:match("/$") then
		if trailing_slash then
			rest = rest .. "/"
		end
	else
		if not trailing_slash then
			rest:gsub("/$", "")
		end
	end

	return CharMap(protocol .. rest)
end

--[=[
	Similarity based on the Sorensen-Dice coefficient.
	Returns a number between 0 and 1, where 0 means no similarity and 1 means identical.
]=]
function CharMap:Similarity(value: string)
	value = CharMap(value)

	if self:IsEqualTo(value) then
		-- Both strings are equally similar
		return 1
	end

	if self:Length() < 2 and value:Length() < 2 then
		-- Both strings are empty or have only one character
		-- No way to calculate similarity without a single bigram
		return 0
	end

	local self_size = self:Length() - 1
	local target_size = value:Length() - 1

	local sum = self_size + target_size
	local inter = 0

	for i = 1, self_size do
		local i0 = self[i]
		local i1 = self[i + 1]

		for j = 1, target_size do
			if i0 == value[j] and i1 == value[j + 1] then
				inter = inter + 1
				break
			end
		end
	end

	return (2 * inter) / sum
end

--[=[
	Splits the string into an array of strings using the given `dilimeter`.
]=]
function CharMap:Split(dilimeter: string)
	local parts = {}
	local pattern = "[^" .. dilimeter:gsub("(%W)", "%%%1") .. "]+"
	for part in self._string:gmatch(pattern) do
		table.insert(parts, part)
	end
	return parts
end

--[=[
	Returns the string.
	Strings are immuteable and passed by value, so no need to duplicate it.
]=]
function CharMap:ToString()
	return self._string
end

return CharMap