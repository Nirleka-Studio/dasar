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
		local s, e, tag = ustring.sfind(u_text, "<([^>]+)>", i)

		if s and s > i then
			local plain_text = ustring.sub(u_text, i, s - 1)
			array.push_back(result, { content = plain_text })
		elseif not s then
			local plain_text = ustring.sub(u_text, i)
			array.push_back(result, { content = plain_text })
			break
		end

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

			local s_2, e_2, enclosing = ustring.sfind(u_text, "<\/([^>]+)>", e + 1)
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
	local default_char_delay: number = char_delay
	local last_time: number = tick()

	-- bother even trying?
	local tag_handlers = {
		["skip"] = function(segment)
			stepper(segment.content._string)
		end,

		["wait"] = function(segment)
			local wait_time = tonumber(segment.content._string) or 0
			task.wait(wait_time)
		end,

		["cps"] = function(segment)
			local content = segment.content._string
			if content == "n" then
				char_delay = default_char_delay
			else
				local new_cps = tonumber(content)
				if new_cps then
					char_delay = 1 / new_cps
				end
			end
		end,
	}

	for _, segment in array.iter(parsed) do
		local tag = segment.tag

		if tag and tag_handlers[tag] then
			tag_handlers[tag](segment)
			continue
		end

		for _, char in array.iter(segment.content._array) do
			while tick() - last_time < char_delay do
				task.wait()
			end

			stepper(char)
			last_time = tick()
		end
	end
end

return urich