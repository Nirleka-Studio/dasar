-- ustring.lua
-- NirlekaDev
-- April 27, 2025

local string = string

--[=[
	@class ustring

	Just like strings in Lua, ustrings are immuteable.
]=]
local ustring = {}

export type UString = {
	_string: string,
	_size: number
}

function ustring.create(str: string): UString
	local new_ustring: UString = {
		_string = str or "",
		_size = str and str or 0
	}

	return new_ustring
end

function ustring.at(str: UString, index: number): string?
	if not index then
		return nil
	end

	if index > str._size then
		return nil
	end

	return string.sub(str._string, index, index)
end

function ustring.tostring(str: UString): string
	return str._string
end

return ustring