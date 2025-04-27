-- rtween.lua
-- NirlekaDev
-- April 27, 2025

local TweenService = game:GetService("TweenService")
local array = require("../containers/array")

--[=[
	@class rtween

	The R stands for Roblox. It is a wrapper around TweenService,
	so it can be implemented in a way similar to Godot's Tween.
	Unlike the `src/modules/animation/tween` which uses an entirely custom
	implemention for tweening.

	Due to being part of the Dasar Standard Library, RTween will take the
	functional programming approach. Standing on the philosphy that everything
	must be explicit.
]=]
local rtween = {}

export type RTween = {
	tweens: { Tween },
	easing_config: {},
	stack: Stack,
	connections: array.Array<RBXScriptConnection>,
	easing_style: Enum.EasingStyle,
	easing_direction: Enum.EasingDirection,
	parallel_enabled: boolean,
	default_parallel: boolean
}

export type Stack = {
	[number] : { Tween }
}

export type PropertyParam = {
	[ string ] : any
}

export type TweenParam = {
	properties: PropertyParam,
	dur: number
}

function rtween.create(
	easing_style: Enum.EasingStyle,
	easing_direction: Enum.EasingDirection
): RTween
	local new_rtween: RTween = {
		tweens = {},
		stack = {},
		easing_config = {},
		connections = array.create(),
		easing_style = easing_style or Enum.EasingStyle.Linear,
		easing_direction = easing_direction or Enum.EasingDirection.InOut,
		parallel_enabled = false,
		default_parallel = false
	}

	return new_rtween
end

function rtween.append_tweens(rtween_inst: RTween, tweens_arr: { Tween })
	local stack = rtween_inst.stack
	local current_step_index = 0

	if rtween_inst.parallel_enabled then
		current_step_index = #stack
	else
		current_step_index = #stack + 1
	end

	rtween_inst.parallel_enabled = rtween_inst.default_parallel

	if not stack[current_step_index] then
		stack[current_step_index] = {}
	end

	local current_step = stack[current_step_index]

	for _, tween in ipairs(tweens_arr) do
		current_step[ #current_step + 1 ] = tween
	end
end

function rtween.play(rtween_inst: RTween)

	-- I should probably tell you how the Stack works.
	-- The Stack holds references to the tweens table,
	-- The Stack contains 'steps' which itself contains the actual tweens.
	-- In each step, all tweens inside will play at the same time.
	-- In order to advance to the next step, all tweens in the current step
	-- has to be completed.

	-- to prevent yielding, run it in another thread
	task.spawn(function()
		local function play_step(step_index)
			if step_index > #rtween_inst.stack then
				-- all steps completed
				return
			end

			local step = rtween_inst.stack[step_index]
			local step_size = #step
			local completed_tweens = 0

			for _, tween in ipairs(step) do
				tween:Play()

				local connection
				connection = tween.Completed:Connect(function()
					completed_tweens += 1
					if completed_tweens == step_size then
						-- all tweens in this step are done
						if connection then
							connection:Disconnect()
						end
						play_step(step_index + 1) -- move to next step
					end
				end)

				array.push_back(rtween_inst.connections, connection)
			end
		end

		-- start from step 1
		play_step(1)
	end)
end

function rtween.kill(rtween_inst: RTween)
	local tweens = rtween_inst.tweens
	for k, tween in ipairs(tweens) do
		tween:Cancel()
		tween:Destroy()
		tweens[k] = nil
	end

	for _, connection: RBXScriptConnection in ipairs(rtween_inst.connections._data) do
		connection:Disconnect()
	end
end

function rtween.pause(rtween_inst: RTween)
	local tweens = rtween_inst.tweens
	for k, tween in ipairs(tweens) do
		tween:Pause()
	end
end

function rtween.tween_instance(
	rtween_inst: RTween,
	inst: Instance,
	properties: PropertyParam,
	dur: number,
	delay: number?,
	easing_style: Enum.EasingStyle?,
	easing_direction: Enum.EasingDirection?
)
	local tween_info = TweenInfo.new(
		dur,
		easing_style or rtween_inst.easing_style,
		easing_direction or rtween_inst.easing_direction,
		nil,
		nil,
		delay or nil
	)
	local tweens_arr = array.create()

	for prop_name, prop_fnl_val in pairs(properties) do
		local tween_inst = TweenService:Create(
			inst,
			tween_info,
			{ prop_name = prop_fnl_val }
		)

		array.push_back(tweens_arr, tween_inst)
	end

	rtween.append_tweens(rtween_inst, tweens_arr._data)
end

return rtween