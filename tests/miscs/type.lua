-- Luau 0.672 bug
local function foo(): ()
	local str: *blocked-153623* | string = "string"

	for i = 1, 1 do
		str = str:gsub() -- blocked-153578
	end
end