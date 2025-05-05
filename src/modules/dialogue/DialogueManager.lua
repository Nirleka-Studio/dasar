-- DialogueManager.lua
-- NirlekaDev
-- April 24, 2025

local Players = game:GetService("Players")

local rtween = require("../../library/animation/rtween")
local Dialogue = require("./Dialogue")

local ui = Players.LocalPlayer.PlayerGui:WaitForChild("Dialogue").root
local ui_dialogue_text: TextLabel = ui.dialogue_backdrop.text
local ui_dialogue_backdrop: Frame = ui.dialogue_backdrop

local tweens_ui_dialogue = rtween.create(Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local function create_tween(current_tween, trans_type, ease_type)
	if current_tween then
		rtween.kill(current_tween)
		current_tween = nil
	end

	current_tween = rtween.create(Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	return current_tween
end

local DialogueManager = {}

function DialogueManager.HideDialogue()
	local tween = create_tween(tweens_ui_dialogue)
	rtween.set_parallel(tween, true)
	rtween.tween_instance(tween, ui_dialogue_text, {TextTransparency = 1}, 1)
	rtween.tween_instance(tween, ui_dialogue_backdrop, {Transparency = 1}, 1)
end

function DialogueManager.ShowDialogue()
	local tween = create_tween(tweens_ui_dialogue)
	rtween.set_parallel(tween, true)
	rtween.tween_instance(tween, ui_dialogue_text, {TextTransparency = 0}, 1)
	rtween.tween_instance(tween, ui_dialogue_backdrop, {Transparency = 0}, 1)
end

function DialogueManager.StepText(text: string, config: Dialogue.DiaConfig?)
	return Dialogue(text, ui_dialogue_text, config)
end

function DialogueManager.ShowText_ForDuration(activeText, showDuration)
	DialogueManager.ShowText_Forever(activeText)
	task.wait(showDuration)
	DialogueManager.HideDialogue()
end

function DialogueManager.ShowText_Forever(activeText)
	DialogueManager.ShowDialogue()
	ui_dialogue_text.Text = activeText
	DialogueManager.StepText(activeText)
end

function DialogueManager.PlaySequence(sequenceText)
	local dialogues = string.split(sequenceText, "\n")

	for _, dialogue in ipairs(dialogues) do
		--dialogue = cleanText(dialogue)

		if dialogue == "" then
			continue
		end

		local waitTime, text = dialogue:match("([%d%.]+)%s+(.+)$")

		if waitTime and text then
			waitTime = tonumber(waitTime)
			local duration, actualText = text:match("@([%d%.]+)%s+(.+)$")

			if duration then
				duration = tonumber(duration)
				actualText = actualText --cleanText(actualText)
				task.wait(waitTime)
				DialogueManager.ShowText_ForDuration(actualText, duration)
			else
				text = text --cleanText(text)
				task.wait(waitTime)
				DialogueManager.ShowText_Forever(text)
			end
		else
			DialogueManager.ShowText_Forever(dialogue)--cleanText(dialogue))
		end
	end
end

return DialogueManager