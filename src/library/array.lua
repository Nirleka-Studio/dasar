-- array.lua
-- NirlekaDev
-- April 26, 2025

--[=[
	@class array
]=]
local array = {}

--[=[
	@within array
]=]
export type Data = { [number] : any }

--[=[
	@within array
]=]
export type Array = {
	_data: { [number] : any },
	_readonly: boolean,
	_size: number,
	_size_updt: boolean
}

function array.create(from: Data?)
	local new_array: Array = {
		_data = from or {},
		_readonly = false,
		_size = 0,
		_size_updt = true
	}

	return new_array
end

return array