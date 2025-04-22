local error = error
local string = string
local format = string.format
local huge = math.huge -- so huge af that its infinite

local MSG_ERR_TYPE = "%s must be of type %s; got %s"

--[=[
	@class assert_macros

	I know the name says "assert" but this module does not use assert functions.
	Just good ol' error function.

	For the sake of that nanosecond of performance, these functions are pretty raw.
	So use them accordingly otherwise there will be an error in the ones that THROWS
	the error,

	He he. Ass Mac.
]=]
local ass_mac = {}

--[=[
	Throws an error if the value's type does not match the expected type.
]=]
function ass_mac.ERR_TYPE(value: any, value_name: string, expected_type: string)
	local value_type = type(value)
	if value_type ~= expected_type then
		error(format(MSG_ERR_TYPE, value_name, expected_type, value_type), huge)
	end
end

--[=[
	Throws an error if the value's false or nil.
]=]
function ass_mac.ERR_FAIL_COND_MSG(value: string, msg: string)
	if not value then
		error(msg, huge)
	end
end

--[=[
	Throws an error if the index of the table is nil.
]=]
function ass_mac.ERR_NIL_INDEX(t: table, index: any)
	if t[index] == nil then
		error(format("t[ %s ] is nil", index))
	end
end

return ass_mac