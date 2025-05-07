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
]=]
local urich = {}

type Array<T> = array.Array<T>
type Segment = { tag: string?, content: ustring.UString }

function urich.parse(text: string)
	local result = array.create()
	local u_text = ustring.create(text)

	local i = 1
	while i <= u_text.length do

		-- this could've been cleaner. But of course, Lua doesn't use the full regex.
		-- it uses simplified, or, ahem, bastardized version of it. Forcing me to
		-- write this terribleness.
		local s, e, tag, tag_content, close_tag = ustring.sfind(u_text, "<([^>]+)>([^<]*)</([^>]+)>", i)

		if (s and e ) and tag == close_tag then
			if s > i then
				local plain_text = ustring.sub(u_text, i, s - 1)
				array.push_back(result, { content = plain_text })
			end

			array.push_back(result, {
				tag = tag,
				content = ustring.create(tag_content)
			})

			i = e + 1
		else
			local plain_text = ustring.sub(u_text, i)
			array.push_back(result, { content = plain_text })
			break
		end
	end

	return result
end

function urich.step(parsed: Array<Segment>, cps: number, stepper: (chars: string) -> ())
	local char_delay: number = 1 / cps
	local last_time: number = tick()

	for _, segment in array.iter(parsed) do
		if segment.tag == "skip" then
			stepper(segment.content._string)
			continue
		elseif segment.tag == "wait" then
			local wait_time = segment.content._string
			if wait_time == "" then
				wait_time = 0
			end

			task.wait(tonumber(wait_time))
			continue
		end

		for i, char in array.iter(segment.content._array) do
			while tick() - last_time < char_delay do
				task.wait() -- delay so the stack wont go sodding
			end

			stepper(char)

			last_time = tick()
		end
	end
end

return urich