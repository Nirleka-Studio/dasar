local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

--[=[
	@class Replicator

	Replicates several instances not replicated automatically
	due to several settings.

	For example, if Players.CharacterAutoLoads is set to false,
	GUIs from StarterGui are not replicated for some reason.
]=]
local Replicator = {}

function Replicator._ready()
	if not Players.CharacterAutoLoads then
		Replicator.ReplicateAllFrom(GuiService, Players.LocalPlayer.PlayerGui)
	end
end

function Replicator.ReplicateAllFrom(from: Instance, to: Instance)
	for _, inst in ipairs(from:GetChildren()) do
		inst:Clone().parent = to
	end
end

return Replicator