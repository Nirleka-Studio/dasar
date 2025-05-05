--!strict

local array = require("../../src/library/containers/array")
local ustring = require("../../src/library/string/ustring")

type Array<T> = array.Array<T>

--[=[
	Ok. This is the most basic kind of implementation for the typewriter effect.
	Simply concats each characters every 1 second.

	This, of course, may lead to problems. Computer processing is, lets say, inconsistent.
	If a poor soul of a user, using a potato computer, it may lag. Causing this to slow down.

	And also putting the delay before a character appears isnt a very convinient way to put it.
]=]
local function typewriter_basic(text: string, label: TextLabel): ()
	local chars: Array<string> = ustring.explode(text)
	local final_text: string = ""

	for i, char in array.iter(chars) do
		final_text = final_text .. array.get(chars, i)
		label.Text = final_text
		task.wait(1)
	end
end

--[=[
	We're getting more advanced now.

	...

	my brain crashed.
	ok bye.
]=]
local function typewriter_delta(text: string, label: TextLabel, cps: number): ()
	local chars: Array<string> = ustring.explode(text)
	local final_text: string = ""
	local char_delay: number = 1 / cps
	local last_time: number = tick()

	for i, char in array.iter(chars) do
		while tick() - last_time < char_delay do
			task.wait(0) -- delay so the stack wont go sodding
		end

		final_text = final_text .. char
		final_text = final_text:gsub()
		label.Text = final_text

		last_time = tick()
	end
end