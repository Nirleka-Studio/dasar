local rotate_left = require("hash_funcs").rotate_left
local bit32 = bit32
local HASH_MURMUR3_SEED = 0

--[=[
	@class hash_murmur

	The MurmurHash3 algorithm for 32 bit.
]=]
local hash_murmur = {}

function hash_murmur.fmix32(h)
	h = bit32.bxor(h, bit32.rshift(h, 16))
	h = (h * 0x85ebca6b) % 4294967296
	h = bit32.bxor(h, bit32.rshift(h, 13))
	h = (h * 0xc2b2ae35) % 4294967296
	h = bit32.bxor(h, bit32.rshift(h, 16))
	return h
end

function hash_murmur.one_32(p_in, p_seed)
	p_seed = p_seed or HASH_MURMUR3_SEED
	p_in = (p_in * 0xcc9e2d51) % 4294967296
	p_in = rotate_left(p_in, 15)
	p_in = (p_in * 0x1b873593) % 4294967296
	p_seed = bit32.bxor(p_seed, p_in)
	p_seed = rotate_left(p_seed, 13)
	p_seed = (p_seed * 5 + 0xe6546b64) % 4294967296
	return p_seed
end

return hash_murmur