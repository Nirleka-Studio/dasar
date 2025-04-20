-- Brewer.lua
-- NirlekaDev
-- April 11, 2025

local ScriptEditorService = game:GetService("ScriptEditorService")

--[=[
	@class Brewer

	Brewer is a singleton class that acts like a sort of package manager for Roblox
	using GitHub.

	Why do I named it Brewer? Because it brews packages for you.
	Nah, just kidding. I actually don't know.
	Though, I did get inspiration from 'Homebrew' package manager for macOS.
]=]
local Brewer = {}
--[[
	"A Man's worse sense of pain is not death. But suffering slowly, which is painful."
		- The Founder, 2025

	This code is made cleanly. With the cost of suffering. That lasted from April 11 to
	April 20.
]]

function Brewer.InstallRepo(rester, branch: string, parent: Instance)
	local dirs, files = rester:GetAllFileContentsAndDirectories({
		tree_sha = branch
	})

	local path_to_instance = {}
	path_to_instance[""] = parent

	local file_data = {}

	for _, item in ipairs(dirs) do
		local folder_inst = Brewer.createFolder(item)
		local current_path = string.match(item.path, "(.*)/[^/]*$") or ""
		local parent_folder = path_to_instance[current_path] or parent

		folder_inst.Parent = parent_folder
		path_to_instance[item.path] = folder_inst
	end

	for _, item in ipairs(files) do
		local parent_path = string.match(item.path, "(.*)/[^/]*$") or ""
		local parent_folder = path_to_instance[parent_path] or parent

		local file_inst = Brewer.createFile(item)
		if file_inst then
			file_inst.Parent = parent_folder
		end
	end

	return parent
end

function Brewer.createFile(dir: { [string] : any })
	if dir.extension == "lua" then
		return Brewer.createModule(dir)
	end

	return nil
end

function Brewer.createFolder(dir: { [string] : any })
	local folder_inst = Instance.new("Folder")
	folder_inst.Name = dir.name

	folder_inst:SetAttribute("path", dir.path)
	folder_inst:SetAttribute("sha", dir.sha)

	return folder_inst
end

function Brewer.createModule(dir: { [string] : any })
	local module_inst = Instance.new("Folder")
	module_inst.Name = dir.name

	module_inst:SetAttribute("path", dir.path)
	module_inst:SetAttribute("sha", dir.sha)

	ScriptEditorService:UpdateSourceAsync(module_inst, function()
		return dir.content
	end)

	return module_inst
end

return Brewer