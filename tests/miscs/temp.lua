--!strict

-- why tf is C++'s std::vector even called a vector????????????
-- alex you fucked up hard
type Vector<T> = { T }

local array: Vector<string> = {}

for i, v in ipairs(array) do
	v = v -- v is string :DDDDDDDDDDD
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

local Rock = {}
Rock.__index = Rock

export type Rock = typeof(setmetatable({}, {})) & {
	getDensity: () -> number,
	__eq: (val: any, other_val: any) -> boolean
}

function Rock.new() : Rock
	local self = {
		density = 77
	}
	local self = setmetatable(self :: any, Rock)

	return self
end

function Rock:__eq(val: any, other_val: any): boolean
	return val == other_val
end

function Rock:getDensity()
	return self.density
end

local new_rock = Rock.new()

print(new_rock == "why")

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

type BITCH = types.