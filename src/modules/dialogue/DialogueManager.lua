local Tween = require("../animation/Tween")
local DiaSegmentMap = require("./DiaSegmentMap")

local ui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Dialogue").root
local ui_dialogue_text = ui.dialogue_backdrop.text
local ui_dialogue_backdrop = ui.dialogue_backdrop

local tweens_ui_dialogue = Tween.new()
	:SetTrans(Tween["ENUM_TRANSITION_TYPES"]["TRANS_CUBIC"])
	:SetEase(Tween["ENUM_EASING_TYPES"]["EASE_IN_OUT"])

local function create_tween(current_tween, trans_type, ease_type)
	if current_tween then
		trans_type = current_tween:GetTrans()
		ease_type = current_tween:GetEase()
		current_tween:Kill()
		current_tween = nil
	end

	--current_tween:Destroy()

	current_tween = Tween.new():SetTrans(trans_type):SetEase(ease_type)
	return current_tween
end

local DialogueManager = {}

function DialogueManager.HideDialogue()
	local tween = create_tween(tweens_ui_dialogue):SetParallel(true)
	tween:TweenProperty(ui_dialogue_text, "TextTransparency", 1, 1)
	tween:TweenProperty(ui_dialogue_backdrop, "Transparency", 1, 1)
end

function DialogueManager.ShowDialogue()
	local tween = create_tween(tweens_ui_dialogue):SetParallel(true)
	tween:TweenProperty(ui_dialogue_text, "TextTransparency", 0, 1)
	tween:TweenProperty(ui_dialogue_backdrop, "Transparency", 0, 1)
end

function DialogueManager.StepText(text: string, config: any?)
	return DiaSegmentMap.StepAndRender(text, ui_dialogue_text, config)
end

return DialogueManager