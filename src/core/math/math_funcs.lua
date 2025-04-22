-- math_funcs.lua
-- NirlekaDev
-- April 21, 2025

local EPSILON = 1e-6

local lib = {}

function lib.lerp(a, b, t)
	return a + (b - a) * t
end

function lib.aproxzero(a, b)
	return math.abs(a - b) < EPSILON
end

return lib