-- Brewer.lua
-- NirlekaDev
-- April 11, 2025

local ScriptEditorService = game:GetService("ScriptEditorService")
local HttpService = game:GetService("HttpService")
local HttpPromise = require("./HttpPromise")
local CharMap = require("../variant/CharMap")
local Rester = require("./Rester")

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
]]

type Blob = {
	sha: string,
	node_id: string,
	size: number,
	url: string,
	content: string,
	encoding: string,
}

type TreeIndex = {
	path: string,
	mode: string,
	type: string,
	sha: string,
	size: number?,
	url: string
}

type TreeData = {
	sha: string,
	url: string,
	tree: { [number] : TreeIndex },
	truncated: string
}

type HttpResponse = {
	Body: string,
	Success: boolean,
	StatusCode: number,
	StatusMessage: string,
	Headers: { [string]: string },
}

--[=[

]=]
function Brewer.install_repo(owner: string, repo: string, branch: string, parent: Instance?)
	local request: HttpResponse = Rester.get_tree_recursive({
		owner = owner,
		repo = repo,
		tree = branch,
	}):awaitValue()

	local tree: TreeData = HttpService:JSONDecode(request.Body) :: TreeData

	return Brewer.create_tree(tree, parent)
end

function Brewer.create_tree(tree: TreeData, parent: Instance?)
	parent = parent or game.ReplicatedStorage

	local path_to_instance = {}
	path_to_instance[""] = parent

	local file_data = {}

	for _, item in ipairs(tree.tree) do
		if item.type == "tree" then
			local folder_inst = Brewer.create_folder(item)
			local current_path = string.match(item.path, "(.*)/[^/]*$") or ""
			local parent_folder = path_to_instance[current_path] or parent

			folder_inst.Parent = parent_folder
			path_to_instance[item.path] = folder_inst
		elseif item.type == "blob" then
			table.insert(file_data, item)
		end
	end

	for _, item in ipairs(file_data) do
		local parent_path = string.match(item.path, "(.*)/[^/]*$") or ""
		local parent_folder = path_to_instance[parent_path] or parent

		local file_inst = Brewer.create_file(item)
		if file_inst then
			file_inst.Parent = parent_folder
		end
	end

	return parent
end

function Brewer.create_file(request: TreeIndex)
	if request.type == "tree" then
		return Brewer.create_folder(request)
	else
		local extension = string.match(CharMap(request.path):LastDelim():ToString(), "%.([^%.]+)$")

		if extension == "lua" then
			return Brewer.create_module(request)
		end
	end

	return nil
end

function Brewer.create_folder(request: TreeIndex)
	local folder_inst = Instance.new("Folder")
	folder_inst.Name = CharMap(request.path):LastDelim("/"):ToString()

	return folder_inst
end

function Brewer.create_module(request: TreeIndex)
	local module_inst = Instance.new("ModuleScript")
	module_inst.Name = string.match(CharMap(request.path):LastDelim("/"):ToString(), "(.+)%.[^%.]+$")

	module_inst:SetAttribute("url", request.Url)
	module_inst:SetAttribute("sha", request.Sha)

	local blob: Blob = HttpPromise.request({
		Url = request.url,
		Method = "GET"
	}):awaitValue()

	-- all of these decoding shit is slowly making me go insane
	local decoded = HttpService:JSONDecode(blob.Body)
	local decoded_content = Rester.base64_decode(decoded.content)

	ScriptEditorService:UpdateSourceAsync(module_inst, function()
		return decoded_content
	end)

	return module_inst
end

return Brewer