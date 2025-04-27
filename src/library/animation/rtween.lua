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
	default_parallel: boolean,
	is_playing: boolean,
	is_paused: boolean,
	current_step: number?
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
		default_parallel = false,
		is_playing = false,
		is_paused = false,
		current_step = nil
	}

	return new_rtween
end

function rtween.append_tweens(rtween_inst: RTween, tweens_arr: { Tween })
	local stack = rtween_inst.stack
	local tweens = rtween_inst.tweens
	local current_step_index = 0

	if rtween_inst.parallel_enabled then
		current_step_index = math.max(1, #stack)
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
		tweens[ #tweens + 1 ] = tween
	end
end

function rtween.play(rtween_inst: RTween)

	-- I should probably tell you how the Stack works.
	-- The Stack holds references to the tweens table,
	-- The Stack contains 'steps' which itself contains the actual tweens.
	-- In each step, all tweens inside will play at the same time.
	-- In order to advance to the next step, all tweens in the current step
	-- has to be completed.

	if rtween_inst.is_playing and not rtween_inst.is_paused then
		return
	end

	for k, connection in ipairs(rtween_inst.connections._data) do
		connection:Disconnect()
		rtween_inst.connections._data[k] = nil
	end

	rtween_inst.is_paused = false

	-- to prevent yielding, run it in another thread
	task.spawn(function()
		local function play_step(step_index)
			if step_index > #rtween_inst.stack then
				-- all steps completed
				rtween_inst.current_step = 1
				rtween_inst.is_playing = false
				return
			end

			rtween_inst.current_step = step_index
			rtween_inst.is_playing = true

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

		play_step(rtween_inst.is_paused and rtween_inst.current_step or 1)
	end)
end

function rtween.kill(rtween_inst: RTween)
	for k, tween in ipairs(rtween_inst.tweens) do
		tween:Cancel()
		tween:Destroy()
		rtween_inst.tweens[k] = nil
	end

	for i, step in ipairs(rtween_inst.stack) do
		for j, _ in ipairs(step) do
			step[j] = nil
		end
		rtween_inst.stack[i] = nil
	end

	for _, connection: RBXScriptConnection in ipairs(rtween_inst.connections._data) do
		connection:Disconnect()
	end

	rtween_inst.current_step = 1
	rtween_inst.is_playing = false
	rtween_inst.is_paused = false
end

function rtween.pause(rtween_inst: RTween)
	rtween_inst.is_paused = true

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
		0,
		false,
		delay or 0
	)
	local tweens_arr = array.create()

	for prop_name, prop_fnl_val in pairs(properties) do
		local tween_inst = TweenService:Create(
			inst,
			tween_info,
			{ [prop_name] = prop_fnl_val }
		)

		array.push_back(tweens_arr, tween_inst)
	end

	rtween.append_tweens(rtween_inst, tweens_arr._data)
end

return rtween