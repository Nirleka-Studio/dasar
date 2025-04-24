-- DiaSegmentMap.lua
-- NirlekaDev
-- March 30, 2025 // Idul Fitr!!

local CHAR_DELAYS = {
	[","] = 0.3,
	["."] = 0.8,
	["!"] = 0.9,
	["|"] = 1.0,
	["?"] = 0.3
}

local FORMAT_TO_REMOVE = {
	["_"] = true,
	["|"] = true
}

--[=[
	@within Dialogue
	Represents the state of each characters in a dialogue.
]=]
export type CharState = {
	char: string,
	state: boolean | "pending" | "fading" | "visibile",
	progress: number,
	startTime: number,
	soundPlayed: boolean
}

--[=[
	@within Dialogue
	Configurations for the dialogue animation.
]=]
export type DiaConfig = {
	cps: number,
	fadeTime: number,
	maxFades: number,
	sound: Sound
}

--[=[
	@within Dialogue
	A segment of a dialogue text seperated by `_`
]=]
export type DiaSegment = {
	text: string,
	skip: boolean
}

--[=[
	@within Dialogue
	More information of each segments.
]=]
export type DiaSegmentData = {
	characters: { CharState },
	skip: boolean,
	cleaned_text: string,
	complete: boolean
}

--[=[
	Returns an array of DiaSegments from the provided text.
]=]
local function splitDialogueSegments(text: string): { DiaSegment }
	local segments: { DiaSegment } = {}

	-- this looks like black magic, because it is. i dont understand it myself.
	-- https://docs.coronalabs.com/guide/data/luaString/index.html
	for plain, word, spaces in text:gmatch("([^_]*)_?([^_]*)_?([ ]*)") do
		if plain ~= "" then
			table.insert(segments, { text = plain, skip = false })
		end
		if word ~= "" then
			table.insert(segments, { text = word .. spaces, skip = true })
		end
	end

	return segments
end

--[=[
	Returns the pause duration listed in `CHAR_DELAYS`
]=]
local function getPauseDuration(char: string): number
	return CHAR_DELAYS[char] or 0
end

--[=[
	Returns a string with the format characters removed.
	Listen in `FORMAT_TO_REMOVE`
]=]
local function removeFormatCharacters(text: string): string
	return text:gsub(".", function(char)
		if FORMAT_TO_REMOVE[char] then
			return ""
		else
			return char
		end
	end)
end

--[=[
	Returns a DiaSegmentData from the provided text.
]=]
local function processSegment(text: string, skip: boolean): DiaSegmentData
	local cleaned_text = removeFormatCharacters(text)
	local characters: { CharState } = {}

	for i = 1, #text do
		local char = text:sub(i, i)
		if not (char:match("%S") or char == " ") then
			continue
		end

		local charState: CharState = {
			char = char,
			state = skip and "visible" or "pending",
			progress = 0,
			startTime = nil,
			soundPlayed = false
		}

		table.insert(characters, charState)
	end

	local segmentData: DiaSegmentData = {
		characters = characters,
		skip = skip,
		cleaned_text = cleaned_text,
		complete = skip or #characters == 0
	}

	return segmentData
end

--[=[
	Updates the fading animation of each characters.
]=]
local function updateCharacters(
	segment: DiaSegmentData,
	current_time: number,
	last_time:{ time: number },
	cps: number,
	fade_time: number,
	max_fades: number
)
	for i, char in ipairs(segment.characters) do
		if not (char.state == "pending" and current_time >= last_time.time + (1 / cps)) then
			continue
		end

		char.state = "fading"
		char.start_time = tick()
		last_time.time = current_time + getPauseDuration(char.char)
		break
	end

	local active_fades = 0
	for _, char in ipairs(segment.characters) do
		if char.state ~= "fading" then
			continue
		end

		active_fades = active_fades + 1
		char.progress = math.min(1, (tick() - char.start_time) / fade_time)

		if char.progress >= 1 then
			char.state = "visible"
			char.soundPlayed = false
		end

		if max_fades and active_fades >= max_fades then
			break
		end
	end
end

--[=[
	Concats (combines) the fading text with the character transparency.
]=]
local function concatCharTransparency(fading_text: string, char: CharState): string
	return fading_text .. string.format('<font transparency="%.2f">%s</font>', 1 - char.progress, char.char)
end

--[=[
	Actually updates the characters to the TextLabel.
]=]
local function renderSegment(label: TextLabel, base_text: string, segment: DiaSegmentData)
	local visible_text = ""
	local fading_text = ""

	for _, char in ipairs(segment.characters) do
		if FORMAT_TO_REMOVE[char.char] then
			continue
		end

		if char.state == "visible" then
			visible_text = visible_text .. char.char
		elseif char.state == "fading" then
			fading_text = concatCharTransparency(fading_text, char)
		end
	end

	label.Text = base_text .. visible_text .. fading_text
end

local function playSound(sound: Sound)
	if sound then
		sound:Play()
	end
end

local function dialogueStepAndRender(text: string, label: TextLabel, p_config: DiaConfig?)
	-- this is so that the type checker will stfu
	local config = p_config or { cps = 20, fadeTime = 0.2, maxFades = 3, sound = nil }

	label.RichText = true
	local segments = splitDialogueSegments(text)
	local full_text = ""
	local last_time = { time = tick() }

	for _, segment_data in ipairs(segments) do
		local segment = processSegment(segment_data.text, segment_data.skip)

		if segment.complete then
			full_text = full_text .. segment.cleaned_text
			label.Text = full_text
		end

		while not segment.complete do
			local current_time = tick()
			updateCharacters(segment, current_time, last_time, config.cps, config.fadeTime, config.maxFades)

			renderSegment(label, full_text, segment)

			segment.complete = true
			for _, char in ipairs(segment.characters) do
				if char.state ~= "visible" then
					segment.complete = false
					break
				end

				if not char.soundPlayed then
					playSound(config.sound)
					char.soundPlayed = true
				end
			end

			task.wait()
		end

		full_text = full_text .. segment.cleaned_text
	end

	label.Text = removeFormatCharacters(text)
end

return dialogueStepAndRender