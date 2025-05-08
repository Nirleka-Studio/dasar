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

	-- this is more complicated than it needs to be.

	-- all i can explain the steps is that
	-- 1. Look for the first tag. (<...>) 2. if it does, check if its an attributed tag <...=...>
	-- 3. if its not, check if its an enclosed that (<...>...</...>)

	-- you'll probably wondering what this is for. well, guess what? its not for markup.
	-- its the backbone of the dialogue system.
	-- the previous system uses symbols and internal delays for specific characters (|, _) which is
	-- a bit too hardcoded and barely extendable.
	-- so the more logical approach is to just parses the string to a set of specific instrunctions.
	-- this is an example: in the original system, its like this "Plain text. _INSTANT APPEAR_| wow.|"
	-- now, this acts as the parser instead of the hard coded engine. So that turns to:
	-- "Plain text.<wait=1> <skip>INSTANT APPEAR</skip><wait=1> wow.<wait=1>"

	-- what about the ustrings? well, those are wrappers around the normal strings except its unicode array.
	-- does it overcomplicate it? No. Heck, all of these ustring functions are basically the string library
	-- functions. And if you did replace them, it'll still work just fine. (if the input is ASCII)
	local i = 1
	while i <= u_text.length do
		local s, e, tag = ustring.sfind(u_text, "<([^>]+)>", i)

		if (s and e) then
			local _, _, att_tag, attribute = string.find(tag, "^(%w+)%s*=%s*(%w+)")
			if (att_tag and attribute) then
				array.push_back(result, { tag = att_tag, content = ustring.create(attribute) })
				i = e + 1
				continue
			end

			-- wtf does this do here? idk.
			if s > i then
				local plain_text = ustring.sub(u_text, i, s - 1)
				array.push_back(result, { content = plain_text })
			end

			local s_2, e_2 = ustring.sfind(u_text, "<\/([^>]+)>", e + 1)
			if (s_2 and e_2) then
				local plain_text = ustring.sub(u_text, e + 1, s_2 - 1)
				array.push_back(result, { tag = tag, content = plain_text })
				i = e_2 + 1
			else
				i = e + 1
			end
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