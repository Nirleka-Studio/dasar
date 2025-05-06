-- urich.lua
-- NirlekaDev
-- May 6, 2025

--!strict

local array = require("../containers/array")
local ustring = require("./ustring")

--[=[
	@class urich

	URich provides basic implementation of Rich Text Format style tags in strings.
	Currently used for the foundation of the dialogue system.
	Helpful site: https://regex101.com
]=]
local urich = {}

type Array<T> = array.Array<T>
type Segment = { tag: string?, content: ustring.UString }
type Command = { tag: string, attribute: any }

function urich.parse(text)
	local result = array.create()
	local u_text = ustring.create(text)

	-- FUTURE: Remove all of these shit altogether and use UString to handle all the bullshit.

	local i = 1  -- character index
	while i <= u_text.length do -- I WAS DOING THE BYTE SIZE AND NOT THE LENGTH PROPERTY?!?!
		-- AND GUESS WHAT?! ITS STILL DOESNT WORK

		-- the fucking byte and actual unicode index bullshit again.
		local byte_i = ustring.char_to_byte_index(text, i) -- OH SO IT WAS YOU
		local s, e, tag, tag_content, close_tag = string.find(text, "<([^>]+)>([^<]*)</([^>]+)>", byte_i)

		-- istg these red underlines makes me want to commit domestic terrorism.
		if s and tag == close_tag then
			-- bother even try?
			local char_s = ustring.byte_to_char_index(text, s)
			local char_e = ustring.byte_to_char_index(text, e)

			if char_s > i then
				local plain_text = ustring.sub(u_text, i, char_s - 1)
				array.push_back(result, { content = plain_text })
			end

			array.push_back(result, {
				tag = tag,
				content = ustring.create(tag_content)
			})

			i = char_e + 1
		else
			local plain_text = ustring.sub(u_text, i)
			array.push_back(result, { content = plain_text })
			break
		end
	end

	-- oh shit it works now.
	-- fuck it. commit.

	return result
end

function urich.step(parsed: Array<Segment>, cps: number, stepper: (chars: string) -> ())
	local char_delay: number = 1 / cps
	local last_time: number = tick()

	for _, segment in array.iter(parsed) do
		if segment.tag == "skip" then
			stepper(segment.content._string)
			continue
		end

		for i, char in array.iter(segment.content._array) do
			while tick() - last_time < char_delay do
				task.wait(0) -- delay so the stack wont go sodding
			end

			stepper(char)

			last_time = tick()
		end
	end
end

return urich