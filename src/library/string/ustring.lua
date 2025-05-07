-- ustring.lua
-- NirlekaDev
-- April 27, 2025

--!strict
local array = require("../containers/array")
local ucaps = require("./ucaps")

local string = string
local table = table
local utf8 = utf8

--[=[
	@class ustring

	The U stands for Unicode.
	A huge problem for Lua strings is that they're byte-oritented,
	not unicode-aware. This makes manipulating multibyte characters
	(used in most non-ASCII languages, like Japanese, and even accented characters)
	unreliable and prone to unexpected results.

	The `ustring` module wraps strings into structured data,
	with propert UTF-8 decoding and safe indexing. Enabling
	consistent Unicode string operations.
]=]
local ustring = {}

export type UString = {
	_string: string,
	_array: Array<string>,
	length: number,
	size: number
}

type Array<T> = array.Array<T>

--[=[
	@within ustring
	Returns a new UString from `str` Lua string.
]=]
function ustring.create(str: string): UString
	local new_ustring: UString = {
		_string = str,
		_array = ustring.explode(str),
		size = #str,
		length = utf8.len(str) :: number -- OH ITS A NUMBER ALRIGHT???
	}

	return new_ustring
end

--[=[
	@within ustring
	Returns the character positioned at `index`
	Unlike using string.sub(), if the index is out of bounds,
	it will return nil instead of an empty string.

	```lua
	local s = ustring.create("月が綺麗ですね。")
	local char = ustring.at(s, 6)
	print(char) -- "す"
	```
]=]
function ustring.at(str: UString, index: number): string?
	if not index then
		return nil
	end

	if index > str.length then
		return nil
	end

	return str._array._data[index]
end

--[=[
	@within ustring
	Useful when you're working with the native Lua string library,
	which can fuck up the index since it operates in bytes.

	```lua
	local s = "月が綺麗ですね。"
	local target = "に"

	-- find the byte index of 'に' in the string
	local byte_start, byte_end = string.find(text, target) -- 7, 9

	local char_index = byte_to_char_index(text, byteStart) -- 3
	```
]=]
function ustring.byte_to_char_index(str: string, byte_index: number): number?
	local char_index = 0
	for p, c in utf8.codes(str) do
		char_index = char_index + 1
		if p >= byte_index then
			return char_index
		end
	end
	return nil
end

function ustring.char_to_byte_index(str: string, char_index: number)
	if not char_index or char_index < 1 then return 1 end
	return utf8.offset(str, char_index) or #str + 1
end

--[=[
	@within ustring
	Returns an array populated with all the characters in `str`
	This also includes whitespaces.

	```lua
	local s = "月が綺麗ですね。"
	local chars = ustring.explode(s)
	print(chars) --[[ {
					[1] = "月",
					[2] = "が",
					[3] = "綺",
					[4] = "麗",
					[5] = "で",
					[6] = "す",
					[7] = "ね",
					[8] = "。"
				 }]]
	```
]=]
function ustring.explode(str: string): Array<string>
	local length = utf8.len(str) :: number
	local chars = array.filled(length, true) :: Array<string>

	-- string.sub() and others operates on bytes. So multibyte characters like `月`
	-- will result in an unknown character. `�`

	local i = 0
	for p, c in utf8.codes(str) do
		i += 1
		array.set(chars, i, utf8.char(c))
	end

	return chars
end

--[=[
	@within ustring
	Returns the UTF-8 codepoint of `char`
]=]
function ustring.get_codepoint(char: string): number
	for p, c in utf8.codes(char) do
		return c
	end
	return -1
end

--[=[
	@within ustring
	Not to be confused with `ustring.size()`,
	This returns the total number of characters in the UString.
	This also includes whitespaces.

	```lua
	local s = ustring.create("月が綺麗ですね。")
	local n = ustring.length(s)
	print(n) -- 8
	```
]=]
function ustring.length(ustr: UString): number
	return ustr.length
end

--[=[
	@within ustring
	A rather internal function used to change the case of all the letters in a
	UString.
]=]
function ustring.change_case(ustr: UString, upper: boolean): UString
	local new_arr = array.filled(ustr.length, true) :: Array<string>

	-- yes. this for making the type checker stfu.
	local func = if upper then ucaps.to_upper else ucaps.to_lower

	for index, char in array.iter(ustr._array) do
		local cp = ustring.get_codepoint(char)
		local upper_cp = func(cp)
		local final_char = utf8.char(upper_cp)

		array.set(new_arr, index, final_char)
	end

	local new_ustr: UString = {
		_string = table.concat(new_arr._data),
		_array = new_arr,
		length = ustr.length,
		size = ustr.size
	}
	return new_ustr
end

--[=[
	@within ustring
	Upper case all the characters in the UString.
	This also accounts for accented characters and others.

	```lua
	local s = ustring.create("Là, vicino al caffè, c'è un bellissimo panorama.")
	local u = ustring.lower(s)
	print(u) -- "LÀ, VICINO AL CAFFÈ, C'È UN BELLISSIMO PANORAMA."
	```
]=]
function ustring.lower(ustr: UString): UString
	return ustring.change_case(ustr, false)
end

--[=[
	@within ustring
	Lower case all the characters in the UString.
	This also accounts for accented characters and others.

	```lua
	local s = ustring.create("LÀ, VICINO AL CAFFÈ, C'È UN BELLISSIMO PANORAMA.")
	local l = ustring.lower(s)
	print(l) -- "Là, vicino al caffè, c'è un bellissimo panorama."
	```
]=]
function ustring.upper(ustr: UString): UString
	return ustring.change_case(ustr, true)
end

--[=[
	@within ustring
	A wrapper around the string.find() function, and works exactly like it.
	Except that the first 2 arguements, which are the start and end index,
	are in character index, not byte index.
]=]
function ustring.sfind(ustr: UString, pattern: string, init: number?, plain: boolean?): (number?, number?, ...string)
	local str = ustring.tostring(ustr)
	local results = { string.find(str, pattern, init, plain) }

	local start_index_byte: number? = results[1]
	local end_index_byte: number? = results[2]

	if start_index_byte and end_index_byte then
		local start_index_char = ustring.byte_to_char_index(str, start_index_byte)
		local end_index_char = ustring.byte_to_char_index(str, end_index_byte)

		-- this only exists to make the typechecker stfu
		local t_results = results :: { string }

		return start_index_char, end_index_char, table.unpack(t_results, 3)
	end

	return nil, nil
end

--[=[
	@within ustring
	Not to be confused with `ustring.length()`,
	This returns the byte size of the UString's string.

	```lua
	local s = ustring.create("月が綺麗ですね。")
	local n = ustring.length(s)
	print(n) -- 24
	```
]=]
function ustring.size(ustr: UString): number
	return ustr.size
end

--[=[
	@within ustring
	Returns a substring of the UString, similar to string.sub() but Unicode-aware.

	```lua
	local s = ustring.create("月が綺麗ですね。")
	local sub = ustring.sub(s, 3, 5)
	print(ustring.tostring(sub)) -- "綺麗で"
	```
]=]
function ustring.sub(str: UString, i: number, j: number?): UString
	if i < 0 then
		i = str.length + i + 1
	end
	if j and j < 0 then
		j = str.length + j + 1
	end

	i = math.max(1, math.min(i, str.length))
	j = j or str.length
	j = math.max(1, math.min(j, str.length))

	if i > j then
		i, j = j, i
	end

	local sub_arr = array.slice(str._array, i, j)
	local sub_str = table.concat(sub_arr._data)

	return ustring.create(sub_str)
end

--[=[
	@within ustring
	Simply returns the original string of the UString.
]=]
function ustring.tostring(str: UString): string
	return str._string
end

return ustring