local HttpService = game:GetService("HttpService")
local ScriptEditorService = game:GetService("ScriptEditorService")

--[=[
	@class HttpRepReq
	@server

	Sends an HTTP request to a GitHub repository and get its contents.

	```lua
	local HttpRepReq = require(game:GetService("ReplicatedStorage").src.core.HttpReqReq
	local owner = "Nirleka-Studio"
	local repo = "dasar"
	local token = "github_pat_TOKEN_HERE"

	local repo_contents = HttpRepReq.GetRepoContents(owner, repo, "", token)
	HttpRepReq.CreateInstancesFromRepo(repo_contents, workspace)
	```
]=]
local HttpRepReq = {}

--[=[
	Returns the repository's contents within the path.
	Remember that this function calls recursively, and without a token,
	it will return Error 403 as you sent too many requests.

	Recommended to use a token to raise the request limit
	[here](https://github.com/settings/personal-access-tokens).
]=]
function HttpRepReq.GetRepoContents(owner: string, repo: string, path: string, token: string)
	local contents = {}
	path = path or ""

	local api_url = string.format("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, path)
	local headers = {
		["Accept"] = "application/vnd.github.v3+json"
	}

	if token then
		headers["Authorization"] = "token " .. token
	end

	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = api_url,
			Method = "GET",
			Headers = headers
		})
	end)

	if not success then
		warn("Failed to get repo contents: " .. tostring(result))
		return contents
	end

	if result.StatusCode ~= 200 then
		warn("API error: " .. result.StatusCode .. " - " .. result.Body)
		return contents
	end

	local data = HttpService:JSONDecode(result.Body)

	for _, item in ipairs(data) do
		if item.type == "file" then
			table.insert(contents, {
				Type = "File",
				Path = item.path,
				Name = item.name,
				Url = item.download_url,
				Size = item.size,
				Sha = item.sha
			})
		elseif item.type == "dir" then
			table.insert(contents, {
				Type = "Directory",
				Path = item.path,
				Name = item.name
			})

			local subContents = HttpRepReq.GetRepoContents(owner, repo, item.path, token)

			for _, subItem in ipairs(subContents) do
				table.insert(contents, subItem)
			end
		end
	end

	return contents
end

--[=[
	Creates actual Instances in the target parent.
	Note that this will only work if you call it from the command bar.
]=]
function HttpRepReq.CreateInstancesFromRepo(contents: { [string]:string }, parent: Instance, rewrite: boolean)
	parent = parent or game.Workspace

	local path_to_instance = {}
	path_to_instance[""] = parent

	local file_data = {}

	for _, item in ipairs(contents) do
		if item.Type == "Directory" then
			local folder = Instance.new("Folder")
			folder.Name = item.Name

			local current_path = string.match(item.Path, "(.*)/[^/]*$") or ""
			local parent_folder = path_to_instance[current_path] or parent

			folder.Parent = parent_folder
			path_to_instance[item.Path] = folder
		elseif item.Type == "File" then
			table.insert(file_data, item)
		end
	end

	for _, item in ipairs(file_data) do
		local file_inst
		local extension = string.match(item.Name, "%.([^%.]+)$")

		file_inst.Name = string.match(item.Name, "(.+)%.[^%.]+$") or item.Name

		local parent_path = string.match(item.Path, "(.*)/[^/]*$") or ""
		local parent_folder = path_to_instance[parent_path] or parent

		file_inst.Parent = parent_folder

		if extension == "lua" then

			local success, file_content = pcall(function()
				return HttpService:GetAsync(item.Url)
			end)

			if success then
				file_inst = Instance.new("ModuleScript")

				if rewrite then

				end

				ScriptEditorService:UpdateSourceAsync(file_inst, function()
					return file_content
				end)
			else
				warn(string.format("Failed to fetch file content '%s': %s", item.Name, tostring(file_content)))
			end
		else
			continue
		end
	end

	return parent
end

return HttpRepReq