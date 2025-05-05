-- math_funcs.lua
-- NirlekaDev
-- April 21, 2025

local EPSILON = 1e-6

local lib = {}

function lib.ease(p_x, p_c)
	if p_x < 0 then
		p_x = 0
	elseif (p_x > 1.0) then
		p_x = 1.0
	end
	if p_c > 0 then
		if (p_c < 1.0) then
			return 1.0 - math.pow(1.0 - p_x, 1.0 / p_c);
		else
			return math.pow(p_x, p_c);
		end
	elseif (p_c < 0) then
		if p_x < 0.5 then
			return math.pow(p_x * 2.0, -p_c) * 0.5;
		else
			return (1.0 - math.pow(1.0 - (p_x - 0.5) * 2.0, -p_c)) * 0.5 + 0.5;
		end
	else
		return 0
	end
end

function lib.lerp(a, b, t)
	return a + (b - a) * t
end

function lib.aproxzero(n)
	return math.abs(n) < EPSILON
end

return lib