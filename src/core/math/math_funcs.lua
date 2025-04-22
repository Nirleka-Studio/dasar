-- math_funcs.lua
-- NirlekaDev
-- April 21, 2025

local EPSILON = 1e-6

local lib = {}

function lib.lerp(a, b, t)
	return a + (b - a) * t
end

function lib.aproxzero(n)
	return math.abs(n) < EPSILON
end

return lib