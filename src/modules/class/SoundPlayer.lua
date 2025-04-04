-- SoundPlayer.lua
-- NirlekaDev
-- April 4, 2025

local Maid = require("Maid")

--[=[
	@class SoundPlayer

	Based on Godot's AudioStreamPlayer.
	Plays a sound non-positionally, ideal for interfaces, menus, or background music.
	Uses the legacy Roblox sound system.
]=]
local SoundPlayer = {}
SoundPlayer.__index = SoundPlayer

function SoundPlayer.new(inst_sound: Sound, inst_pitch: PitchShiftSoundEffect, autoplay: boolean)
	setmetatable({
		_data = {
			autoplay = autoplay or false,
			inst_pitch = inst_pitch,
			inst_sound = inst_sound,
			paused = false,
			pitch_scale = 0,
			playing = false,
		},

		_maid = Maid.new()
	}, SoundPlayer)
end

function SoundPlayer:__index(index)
	if SoundPlayer[index] then
		return SoundPlayer[index]
	elseif self._data[index] then
		return self._data[index]
	else
		return self[index]
	end
end

function SoundPlayer:__newindex(index, value)
	local indexed = self._data[index]
	if not indexed or typeof(indexed) ~= value then
		return
	end

	self._data[index] = value

	if indexed == "paused" then
		if value then
			self:Pause()
		else
			self:Play()
		end
	elseif indexed == "playing" then
		if value then
			self:Play()
		else
			self:Pause()
		end
	elseif indexed == "pitch_scale" then
		self.inst_pitch.Octave = value
	end
end

function SoundPlayer.fromId(rbxassetid: string, autoplay: boolean)
	local sound = Instance.new("Sound")
	local pitch = Instance.new("PitchShiftSoundEffect")

	sound.SoundId = rbxassetid
	pitch.Parent = sound
	sound.Parent = workspace

	local sound_player = SoundPlayer.new(sound, pitch, autoplay)
	sound_player._maid:AddTasksArray({
		sound,
		pitch
	})

	return sound_player
end

function SoundPlayer:GetPlaybackPosition()
	return self.inst_sound.TimePosition
end

function SoundPlayer:GetSoundInstance()
	return self.inst_sound
end

function SoundPlayer:Pause()
	self.paused = true
	self.playing = false
	self.inst_sound:Pause()
end

function SoundPlayer:Play(from_position: number)
	from_position = from_position or 0

	if from_position > self.inst_sound.TimeLength then
		return
	end

	self.inst_sound.TimePosition = from_position

	self.paused = false
	self.playing = true
	self.inst_sound:Play()
end

function SoundPlayer:Stop()
	self.paused = false
	self.playing = false
	self.inst_sound:Stop()
end

return SoundPlayer