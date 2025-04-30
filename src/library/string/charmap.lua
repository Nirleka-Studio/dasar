-- charmap.lua
-- NirlekaDev
-- April 27, 2025

--!strict

local array = require("../containers/array")

export type CharMap = {
	_map: array.Array<string>,
	_size: number
}

local charmap = {}

function charmap.create(str: string): CharMap
	local new_charmap: CharMap = {
		_map = charmap.explode(str),
		_size = #str or 0
	}

	return new_charmap
end

function charmap.at(charmap: CharMap, index: number): string?
	return array.get(charmap._map, index)
end

function charmap.concat(from: CharMap, to: CharMap): CharMap
	local concatenated: array.Array<string> = array.concat_array(to._map, from._map)
	local new_charmap: CharMap = {
		_map = concatenated,
		_size = array.size(concatenated)
	}

	return new_charmap
end

function charmap.explode(str: string)
	local characters = array.create()

	for i = 1, #str do
		array.push_back(characters, str:sub(i,i))
	end

	return characters
end

return charmap