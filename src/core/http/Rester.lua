-- Rester.lua
-- NirlekaDev
-- April 15, 2025

local CharMap = require("../variant/CharMap")
local HttpPromise = require("./HttpPromise")

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
	get_tree_recursive = "GET /repos/{owner}/{repo}/git/trees/{tree}?recursive=1",
	get_rate_limit = "GET /rate_limit",
	get_user = "GET /user",
	get_ref = "GET /repos/{owner}/{repo}/git/ref/heads/{branch}"
}

local HEADERS_ALIASES = {
	auth = "Authentication",
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

type RequestParameter = {
	headers: { [string] : string }?,
	owner: string?,
	repo: string?,
	path: string?,
	tree: string?,
	recursive: boolean,
	ref: string?
}

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

function Rester.new()
	return setmetatable({
		auth = "",
		owner = "",
		repo = "",
		path = ""
	}, Rester)
end

function Rester:ValidateAuthentication()
	return Rester.request(ENDPOINTS.get_user)
end

--[=[

]=]
function Rester.getCommit(request_param: RequestParameter)
	assert(type(request_param) == "table", "`request_param` must be a table")

	return Rester.request(ENDPOINTS.get_commit, request_param)
end

--[=[

]=]
function Rester.getContent(request_param: RequestParameter)
	--[[
		"A function that basically does the same shit by calling another function
		but shortens the operation so you can be a lazy little shit is a good function."
			- The Founder, 2025
	]]
	assert(type(request_param) == "table", "`request_param` must be a table")

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
	assert(type(endpoint) == "string", "`endpoint` must be a string")
	assert(type(request_param) == "table", "`endpoint` must be a table")

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

]=]
function Rester.getRef(request_param: RequestParameter)
	assert(type(request_param) == "table", "`request_param` must be a table")

	return Rester.request(ENDPOINTS.get_ref, request_param)
end

--[=[

]=]
function Rester.getTree(request_param: RequestParameter)
	assert(type(request_param) == "table", "`request_param` must be a table")

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
	if not type(method) == "string"	then
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
	assert(type(data) == "string", "`endpoint` must be a string")

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
	assert(type(endpoint) == "string", "`endpoint` must be a string")
	assert(type(request_param) == "table", "`request_param` must be a table")

	local method, final_path = Rester.getMethodAndPath(endpoint, request_param)

	local headers = {
		["Accept"] = DEFAULT_MEDIA_TYPE,
	}

	if request_param.headers then
		for key, value in pairs(request_param.headers) do
			if HEADERS_ALIASES[key] then
				headers[HEADERS_ALIASES[key]] = value
			else
				headers[key] = value
			end
		end
	end

	local url = URL_GITHUB_API .. "/" .. final_path:gsub("^/", "")

	return HttpPromise.request({
		Url = url,
		Method = method,
		Headers = headers
	})
end

return Rester
