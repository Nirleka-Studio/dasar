-- Rester.lua
-- NirlekaDev
-- April 15, 2025

local AssertMacros = require("../error/assert_macros")
local CharMap = require("../variant/CharMap")
local HttpPromise = require("./HttpPromise")

local ERR_TYPE = AssertMacros.ERR_TYPE

local DEFAULT_MEDIA_TYPE = "application/vnd.github.v3+json"
local URL_GITHUB_API = "https://api.github.com"

local HTTP_VALID_METHODS = {
	["GET"] = true,
	["POST"] = true,
	["PATCH"] = true,
	["PUT"] = true,
	["DELETE"] = true
}

local ENDPOINTS = {
	get_commit = "GET /repos/{owner}/{repo}/git/commits/{commit_sha}",
	get_content = "GET /repos/{owner}/{repo}/contents/{path}",
	get_tree = "GET /repos/{owner}/{repo}/git/trees/{tree_sha}",
	get_tree_recursive = "GET /repos/{owner}/{repo}/git/trees/{tree_sha}?recursive=1",
	get_rate_limit = "GET /rate_limit",
	get_user = "GET /user",
	get_ref = "GET /repos/{owner}/{repo}/git/ref/heads/{branch}"
}

local HEADERS_ALIASES = {
	auth = "Authorization",
	accept = "Accept",
}

--[=[
	@class Rester

	Makes your life less shittier (but still shit) when interacting with the Github REST API.
	Based on the already confusing "Octokit.js" and the dogshit of a documentation.

	Rester? So thats why. It rests my mental state 6 feet under.

	I swear to fucking god the GitHub API returns the most inconsistent shit.
]=]
local Rester = {}
Rester.__index = Rester

export type ResterDir = {
	name: string,
	path: string,
	sha: string
}

export type ResterFile = {
	content: string,
	extension: string,
	name: string,
	path: string,
	sha: string
}

export type ContentResponse = {
	name: string,
	path: string,
	sha: string,
	size: number,
	url: string,
	html_url: string,
	git_url: string,
	download_url: string,
	type: string,
	content: string,
	encoding: string,
	_links: {
		self: string,
		git: string,
		html: string
	},
}

export type RequestParameter = {
	branch: string,
	commit_sha: string,
	headers: { [string] : string }?,
	owner: string?,
	repo: string?,
	path: string?,
	tree_sha: string?,
	recursive: boolean,
	ref: string?
}

export type TreeIndex = {
	path: string,
	mode: string,
	type: string,
	sha: string,
	size: number?,
	url: string
}

export type TreeData = {
	sha: string,
	url: string,
	tree: { [number] : TreeIndex },
	truncated: string
}

export type HttpResponse = {
	Body: string,
	Success: boolean,
	StatusCode: number,
	StatusMessage: string,
	Headers: { [string]: string },
}

function Rester.new(auth: string, owner: string, repo: string)
	return setmetatable({
		auth = auth,
		owner = owner,
		repo = repo
	}, Rester)
end

--[=[
	Validates the authentication key.
]=]
function Rester:ValidateAuthentication()
	return Rester.request(ENDPOINTS.get_user)
end

--[=[
	Returns the directories and files in arrays.
	Automatically decodes the file contents if it is in base64.
]=]
function Rester:GetAllFileContentsAndDirectories(request_param: RequestParameter)
	ERR_TYPE(request_param, "request_param", "table")

	-- magic, do not touch
	local tree: TreeData = Rester.getTree({
		owner = self.owner,
		repo = self.repo,
		tree_sha = request_param.tree_sha,
		headers = {
			auth = self.auth
		},
		recursive = true
	}):andThen(HttpPromise.decodeJson)
		:catch(HttpPromise.logFailedRequests)
		:awaitValue()

	local directories = {}
	local files = {}

	for _, index: TreeIndex in pairs(tree.tree) do
		if index.type == "tree" then
			local new_dir: ResterDir = {}

			new_dir.name = CharMap(index.path):LastDelim("/"):ToString()
			new_dir.path = index.path
			new_dir.sha = index.sha

			table.insert(directories, new_dir)

		elseif index.type == "blob" then
			local new_file: ResterFile = {}

			-- i still dont know how or why this works. dont ask me.
			new_file.extension = string.match(CharMap(index.path):LastDelim("/"):ToString(), "%.([^%.]+)$")
			new_file.path = index.path
			new_file.sha = index.sha
			new_file.name = string.match(CharMap(index.path):LastDelim("/"):ToString(), "(.+)%.[^%.]+$")

			-- another black magic.
			local fetch_content: ContentResponse = Rester.getContent({
				owner = self.owner,
				repo = self.repo,
				path = index.path,
				headers = {
					auth = self.auth
				},
			}):andThen(HttpPromise.decodeJson)
				:catch(HttpPromise.logFailedRequests)
				:awaitValue()

			if fetch_content.encoding == "base64" then
				new_file.content = Rester.base64Decode(fetch_content.content)
			else
				-- im not supporting anymore bullshit
				new_file.content = fetch_content.content
			end

			table.insert(files, new_file)
		end
	end

	return directories, files
end

--[=[
	Returns the contents of a single commit reference.
	You must have `read` access for the repository to use this endpoint.
]=]
function Rester.getCommit(request_param: RequestParameter)
	ERR_TYPE(request_param, "request_param", "table")

	return Rester.request(ENDPOINTS.get_commit, request_param)
end

--[=[
	Gets the contents of a file or directory in a repository.
	Specify the file path or directory with the `path` parameter.
	If you omit the `path` parameter, you will receive the contents
	of the repository's root directory.
]=]
function Rester.getContent(request_param: RequestParameter)
	--[[
		"A function that basically does the same shit by calling another function
		but shortens the operation so you can be a lazy little shit is a good function."
			- The Founder, 2025
	]]
	ERR_TYPE(request_param, "request_param", "table")

	return Rester.request(ENDPOINTS.get_content, request_param)
end

--[=[
	Returns the uppercased method and formatted path from a string.
	Automatically normalizes the URL for any repeated '/' characters,

	```lua
	local endpoint = "GET repos/{owner}/{repo}/contents"
	local request_param = {
		owner = "Nirleka-Studio",
		repo = "dasar"
	}
	local method, path = Rester.getMethodAndPath(endpoint, request_param)
	print(method, path) -- "GET", "repos/Nirleka-Studio/dasar/contents"
	```
]=]
function Rester.getMethodAndPath(endpoint: string, request_param: RequestParameter)
	ERR_TYPE(endpoint, "endpoint", "string")
	ERR_TYPE(request_param, "request_param", "table")

	endpoint = CharMap(endpoint)
	local segments = endpoint:Split(" ")
	local method = segments[1]:upper()

	if not Rester.isValidMethod(method) then
		error("Invalid HTTP method "..method, 4)
	end

	local endpoint_template = CharMap(segments[2]):UrlNormalize()
	local final_path = endpoint_template:Format(request_param)

	return method, final_path
end

--[=[
	Returns a single reference from your Git database.
	The {ref} in the URL must be formatted as heads/<branch name>
	for branches and tags/<tag name> for tags.
	If the {ref} doesn't match an existing ref, a 404 is returned.
]=]
function Rester.getRef(request_param: RequestParameter)
	ERR_TYPE(request_param, "request_param", "table")

	return Rester.request(ENDPOINTS.get_ref, request_param)
end

--[=[
	Returns a single tree using the SHA1 value or ref name for that tree.

	If truncated is true in the response then the number of items in the tree array
	exceeded our maximum limit. If you need to fetch more items, use the non-recursive method
	of fetching trees, and fetch one sub-tree at a time.
]=]
function Rester.getTree(request_param: RequestParameter)
	ERR_TYPE(request_param, "request_param", "table")

	local endpoint
	if request_param.recursive then
		-- i dont know why we have a seperate endpoint for a tree recursive.
		-- but eh.
		endpoint = ENDPOINTS.get_tree_recursive
	else
		endpoint = ENDPOINTS.get_tree
	end

	return Rester.request(endpoint, request_param)
end

--[=[
	Returns true if the provided method is a string and a valid
	HTTP method. Which are defined in the HTTP/1.1 protocol specification in RFC 7231.
	Includes DELETE, GET, POST, PUT, PATCH, DELETE.

	Non case sensitive.
]=]
function Rester.isValidMethod(method: string)
	if type(method) ~= "string"	then
		return false
	end

	return HTTP_VALID_METHODS[method:upper()] ~= nil
end

--[=[
	Taken from [a DevForum post](https://devforum.roblox.com/t/base64-encoding-and-decoding-in-lua/
	Decodes a base64 string into a normal string.

	```lua
	local decoded = Brewer.DecodeBase64("SGVsbG8gV29ybGQh")
	print(decoded) -- "Hello World!"
	```
]=]
function Rester.base64Decode(data: string)
	ERR_TYPE(data, "data", "string")

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
	Returns an HttpPromise object with the given request.

	```lua
	Rester.request("GET /repos/{owner}/{repo}/{path}", {
		owner = "Nirleka-Studio",
		repo = "dasar",
		path = ""
		headers = {
			["Accept"] = "application/vnd.github+json"
		}
	})
	```
]=]
function Rester.request(endpoint: string, request_param: RequestParameter?)
	ERR_TYPE(endpoint, "endpoint", "string")
	ERR_TYPE(request_param, "request_param", "table")

	local method, final_path = Rester.getMethodAndPath(endpoint, request_param)

	local headers = {
		["Accept"] = DEFAULT_MEDIA_TYPE,
	}

	if request_param.headers then
		for key, value in pairs(request_param.headers) do
			print(key, value)
			if HEADERS_ALIASES[key] then
				print("FUCK, THERE IS!", key, value)
				headers[HEADERS_ALIASES[key]] = value
			else
				headers[key] = value
			end
		end
	end

	-- im getting lazy at this point.
	if headers.Authorization then
		print(headers)
		headers.Authorization = "Bearer "..headers.Authorization
	end

	local url = URL_GITHUB_API .. "/" .. final_path:gsub("^/", "")
	
	print(url, headers, request_param)

	return HttpPromise.request({
		Url = url,
		Method = method,
		Headers = headers
	})
end

return Rester