local StarterGui = game:GetService("StarterGui")
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
		Replicator.ReplicateAllFrom(StarterGui, Players.LocalPlayer.PlayerGui)
	end
end

function Replicator.ReplicateAllFrom(from: Instance, to: Instance)
	for _, inst in ipairs(from:GetChildren()) do
		print(inst)
		local inst_clone = inst:Clone()
		print(inst_clone)
		inst_clone.Parent = to
	end
end

return Replicator