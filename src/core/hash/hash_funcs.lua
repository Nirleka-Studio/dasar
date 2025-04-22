local bit32 = bit32

--[=[
	@class hash_funcs

	Provides some common hash functions.
]=]
local lib = {}

function lib.rotate_right(a, n)
	return bit32.bor(bit32.rshift(a, n), bit32.lshift(a, 32 - n))
end

function lib.rotate_left(a, n)
	return bit32.bor(bit32.lshift(a, n), bit32.rshift(a, 32 - n))
end

return lib