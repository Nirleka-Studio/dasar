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
	A huge problem for Lua strings is that
]=]
local ustring = {}

export type UString = {
	_string: string,
	_array: Array<string>,
	length: number,
	size: number
}

type Array<T> = array.Array<T>

function ustring.create(str: string): UString
	local new_ustring: UString = {
		_string = str,
		_array = ustring.explode(str),
		size = #str,
		length = utf8.len(str) :: number -- OH ITS A NUMBER ALRIGHT???
	}

	return new_ustring
end

function ustring.at(str: UString, index: number): string?
	if not index then
		return nil
	end

	if index > str.length then
		return nil
	end

	return str._array._data[index]
end

function ustring.explode(str: string): Array<string>
	local length = utf8.len(str) :: number
	local chars = array.filled(length, true) :: Array<string>

	-- string.sub() and others operates on bytes. So multibyte characters like `月`
	-- will result in an unknown character. `�`
	for p, c in utf8.codes(str) do
		array.set(chars, p, utf8.char(c))
	end

	return chars
end

function ustring.get_codepoint(char: string): number
	for p, c in utf8.codes(char) do
		return c
	end
	return -1
end

function ustring.length(ustr: UString): number
	return ustr.length
end

function ustring.change_case(ustr: UString, method: string): UString
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

function ustring.lower(ustr: UString): UString
	return ustring.change_case(ustr, "to_lower")
end

function ustring.upper(ustr: UString): UString
	return ustring.change_case(ustr, "to_upper")
end

function ustring.size(ustr: UString): number
	return ustr.size
end

function ustring.tostring(str: UString): string
	return str._string
end

return ustring