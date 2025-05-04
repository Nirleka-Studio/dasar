-- ustring.lua
-- NirlekaDev
-- April 27, 2025

--!strict
local array = require("../containers/array")
local ucaps = require("./ucaps")

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
function ustring.change_case(ustr: UString, method: "to_lower" | "to_upper"): UString
	local new_arr = array.filled(ustr.length, true) :: Array<string>

	for index, char in array.iter(ustr._array) do
		local cp = ustring.get_codepoint(char)
		-- "TypeError: Cannot add indexer to table 'ucaps'" that means jackshit to me.
		local upper_cp = ucaps[method](cp)
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
	return ustring.change_case(ustr, "to_lower")
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
	return ustring.change_case(ustr, "to_upper")
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
	Simply returns the original string of the UString.
]=]
function ustring.tostring(str: UString): string
	return str._string
end

return ustring