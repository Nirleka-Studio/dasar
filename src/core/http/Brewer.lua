-- Brewer.lua
-- NirlekaDev
-- April 11, 2025

local ScriptEditorService = game:GetService("ScriptEditorService")
local HttpPromise = require("./HttpPromise")

local FOLDER_ROOT = game:GetService("ReplicatedStorage"):FindFirstChild("src")
local TOKEN = nil
local GITHUB_REPO = {
	owner = "Nirleka-Studio",
	repo = "dasar",
	token = TOKEN
}
local GITHUB_API_LINK = "https://api.github.com/repos/%s/%s/contents/%s"

--[=[
	@class Brewer

	Brewer is a singleton class that acts like a sort of package manager for Roblox
	using GitHub.

	Why do I named it Brewer? Because it brews packages for you.
	Nah, just kidding. I actually don't know.
	Though, I did get inspiration from 'Homebrew' package manager for macOS.
]=]
local Brewer = {}

function Brewer.CheckForUpdates()
	local modules = {}

	if not FOLDER_ROOT then
		local new_folder = Instance.new("Folder")
		new_folder.Name = "src"
		new_folder.Parent = game:GetService("ReplicatedStorage")
		new_folder = new_folder
	end

	for _, child in ipairs(FOLDER_ROOT:GetChildren()) do
		if child:IsA("ModuleScript") then
			local is_of_repo = Brewer.IsModuleOfRepo(GITHUB_REPO.repo)

			if not is_of_repo then
				continue
			end

			local module_sha = child:GetAttribute("sha")

			if module_sha ~= is_of_repo.sha then
				table.insert(modules, child)
			end
		end
	end

	return #modules > 0, modules
end

function Brewer.CreateFile(request: { [string]: string })
	if request.type == "Directory" then
		return Brewer.CreateFolder(request)
	else
		local extension = string.match(request.Name, "%.([^%.]+)$")

		if extension == "lua" then
			return Brewer.CreateModule(request)
		end
	end

	return nil
end

function Brewer.CreateFolder(request: { [string]: string })
	local folder_inst = Instance.new("Folder")
	folder_inst.Name = request.Name

	return folder_inst
end

function Brewer.CreateModule(request: { [string]: string })
	print(request)
	local module_inst = Instance.new("ModuleScript")
	module_inst.Name = string.match(request.Name, "(.+)%.[^%.]+$")

	module_inst:SetAttribute("url", request.Url)
	module_inst:SetAttribute("sha", request.Sha)

	ScriptEditorService:UpdateSourceAsync(module_inst, function()
		return request.Content.Body
	end)

	return module_inst
end

function Brewer.CreateTree(contents: { [number]:string }, parent: Instance, rewrite: boolean)
	parent = parent or game.Workspace

	local path_to_instance = {}
	path_to_instance[""] = parent

	local file_data = {}

	for _, item in ipairs(contents) do
		print(item.Name)
		if item.Type == "Directory" then
			print("creating directory")
			local folder_inst = Brewer.CreateFolder(item)
			local current_path = string.match(item.Path, "(.*)/[^/]*$") or ""
			local parent_folder = path_to_instance[current_path] or parent

			folder_inst.Parent = parent_folder
			path_to_instance[item.Path] = folder_inst
		elseif item.Type == "File" then
			print("passing directory")
			table.insert(file_data, item)
		end
	end

	for _, item in ipairs(file_data) do
		local parent_path = string.match(item.Path, "(.*)/[^/]*$") or ""
		local parent_folder = path_to_instance[parent_path] or parent

		local file_inst = Brewer.CreateFile(item)
		if file_inst then
			file_inst.Parent = parent_folder
		end
	end

	return parent
end

function Brewer.IsModuleOfRepo(repo: string, module: ModuleScript)
	if type(repo) ~= "string" then
		return false
	end

	if not (typeof(module) == "Instance" and module:IsA("ModuleScript")) then
		return false
	end

	local module_url = module:GetAttribute("url")

	if not module_url then
		return false
	end

	local decoded_module_url = Brewer.DecodeLink(module_url)

	if decoded_module_url.owner ~= GITHUB_REPO.owner then
		return false
	end

	if decoded_module_url.repo ~= GITHUB_REPO.repo then
		return false
	end

	local request = Brewer.GetRequest(module_url, GITHUB_REPO.token):awaitValue()

	if request.Success and request.StatusCode == 200 then
		return request.Body
	else
		return nil
	end
end


--// HTTP SUPPROTERS

type ModuleInfo = {
	Type: "File",
	Path: string,
	Name: string,
	Url: string,
	Size: number,
	Sha: string,
	Content: string
}

type DirInfo = {
	Type: "Directory",
	Path: string,
	Name: string
}

type RepoLinkArr = {
	owner: string,
	repo: string,
	path: string
}

type HttpGetRequest = {
	Url: string,
	Method: string,
	Headers: {
		["Accept"]: "application/vnd.github.v3+json",
		["Authorization"]: string?
	}
}

--[=[
	Creates a standardized HTTP GET request object for GitHub API calls.
	Automatically includes required GitHub API headers and authentication.
]=]
function Brewer.CreateHttpGetRequest(url: string, token: string): HttpGetRequest
	local headers = {
		["Accept"] = "application/vnd.github.v3+json"
	}

	if token then
		headers["Authorization"] = "token " .. token
	end

	return {
		Url = url,
		Method = "GET",
		Headers = headers
	}
end

--[=[
	Taken from [a DevForum post](https://devforum.roblox.com/t/base64-encoding-and-decoding-in-lua/
	Decodes a base64 string into a normal string.

	```lua
	local decoded = Brewer.DecodeBase64("SGVsbG8gV29ybGQh")
	print(decoded) -- "Hello World!"
	```
]=]
function Brewer.DecodeBase64(data: string): string
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	data = string.gsub(data, '[^'..b..'=]', '')

	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

--[=[
	Returns an array of strings containing the owner, repo, and path from a GitHub API link.

	```lua
	local decoded = Brewer.DecodeLink("https://api.github.com/repos/Nirleka-Studio/dasar/src")
	print(decoded.owner) -- "Nirleka-Studio"
	print(decoded.repo) -- "dasar"
	print(decoded.path) -- "src"
	```
]=]
function Brewer.DecodeLink(link: string): RepoLinkArr
	local owner, repo, path = link:match("https://api%.github%.com/repos/([^/]+)/([^/]+)/(.*)")
	local arr: RepoLinkArr = {
		owner = owner,
		repo = repo,
		path = path
	}
	return arr
end

--[=[
	Takes in paramaters of owner, repo, and path or a single RepoLinkArr,
	and returns a GitHub API link.

	```lua
	local encoded = Brewer.EncodeLink("Nirleka-Studio", "dasar", "src")
	print(encoded) -- "https://api.github.com/repos/Nirleka-Studio/dasar/src"
	```
]=]
function Brewer.EncodeLink(...: string | RepoLinkArr): string
	local args = table.pack(...)
	local owner, repo, path

	if #args == 1 and type(args[1]) == "table" then
		local tbl = args[1]
		owner = tbl.owner
		repo = tbl.repo
		path = tbl.path
	else
		owner = args[1]
		repo = args[2]
		path = args[3]
	end

	return string.format(GITHUB_API_LINK, owner, repo, path or "")
end

function Brewer.GetContents(path: string)
	local contents = {}

	local request = Brewer.GetRequest(Brewer.EncodeLink(
		GITHUB_REPO.owner,
		GITHUB_REPO.repo,
		path
		)
	):awaitValue()

		or
		Brewer.GetRequest(
			Brewer.EncodeLink(GITHUB_REPO.owner, GITHUB_REPO.repo),
			GITHUB_REPO.token
		):awaitValue()


	if not (request.Success and request.StatusCode == 200) then
		return contents
	end

	local data = HttpPromise.decodeJson(request):awaitValue()

	for _, item in ipairs(data) do
		if item.type == "file" then
			local file_metadata_req = Brewer.GetRequest(item.download_url, GITHUB_REPO.token):awaitValue()

			table.insert(contents, {
				Type = "File",
				Path = item.path,
				Name = item.name,
				Url = item.url,
				Size = item.size,
				Sha = item.sha,
				Content = file_metadata_req
			})
		elseif item.type == "dir" then
			table.insert(contents, {
				Type = "Directory",
				Path = item.path,
				Name = item.name
			})

			local sub_contents = Brewer.GetContents(item.path)

			for _, sub_item in ipairs(sub_contents) do
				table.insert(contents, sub_item)
			end
		end
	end

	return contents
end

function Brewer.GetRequest(url: string, token: string)
	local request = Brewer.CreateHttpGetRequest(url, TOKEN)

	return HttpPromise.request(request)
end

return Brewer