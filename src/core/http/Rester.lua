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
	get_content = "GET /repos/{owner}/{repo}/contents/{path}",
	get_tree = "GET /repos/{owner}/{repo}/git/trees/{tree_sha}",
	get_tree_recursive = "GET /repos/{owner}/{repo}/git/trees/{tree}?recursive=1",
	get_rate_limit = "GET /rate_limit",
	get_user = "GET /user"
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
	tree: string?
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
	It decodes Base64 to normal string. What are you fucking stupid?
	Do I have to write this out for you??? huh????

	This Rester shit is originally written in April 15. Now its 18. How many fucking days
	have i tried to fix this shitty bastard?

	This function exists cuz github is a piece of shit and returns base64 content while in other
	endpoints it returns the raw URL. Im fucking needing a therapist after this shit.

	Taken from [a DevForum post](https://devforum.roblox.com/t/base64-encoding-and-decoding-in-lua/
	Decodes a base64 string into a normal string.

	```lua
	local decoded = Brewer.DecodeBase64("SGVsbG8gV29ybGQh")
	print(decoded) -- "Hello World!"
	```
]=]
function Rester.base64_decode(data: string)
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
	TODO: Im too mentally fucked to write this shitty doc.
]=]
function Rester.get_content(request_param: { [string]: any })
	--[[
		"A function that basically does the same shit by calling another function
		but shortens the operation so you can be a lazy little shit is a good function."
			- The Founder, 2025
	]]

	return Rester.request(ENDPOINTS, request_param)
end

--[=[
	Returns the response of the request to `https://api.github.com/rate_limit`
	to get the rate limit of the current IP address. Or the given token.
	Does not reduce the rate limit when called.

	```lua
	local response = Rester.get_limit():awaitValue()
	print(response) --[[
	{
		["rate"] = {
			["limit"] = 60,
			["remaining"] = 60,
			["reset"] = 1744825954,
			["resource"] = "core",
			["used"] = 0
		},
		...
	}]]
	```
]=]
function Rester.get_limit(token: string?)
	return Rester.request(ENDPOINTS.get_rate_limit, {})
end

--[=[
	Returns the entire tree with its SHA or branch name.
	Lists all the files.

	```lua
	Rester.get_tree_recursive({
		owner = "Nirleka-Studio",
		repo = "dasar",
		tree = "master"
	})
	```
]=]
function Rester.get_tree_recursive(request_param: RequestParameter)
	return Rester.request(ENDPOINTS.get_tree_recursive, request_param)
end

--[=[
	Returns true if the given method is a valid HTTP method.
	Which includes GET, POST, PUT, DELETE.

	```lua
	print(Rester.http_validate_method("GET")) -- true
	print(Rester.http_validate_method("FLY")) -- false
	```
]=]
function Rester.http_validate_method(method: string)
	if type(method) ~= "string" then
		return false
	end

	return HTTP_VALID_METHODS[method:upper()] == true
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
function Rester.request(base_url: string, request_param: RequestParameter?)
	assert(type(base_url) == "string", "`base_url` must be a string")
	assert(type(request_param) == "table", "`request_param` must be a table")

	base_url = CharMap(base_url)
	local segments = base_url:Split(" ")
	local method = segments[1]:upper()
	local endpoint_template = CharMap(segments[2]):UrlNormalize()

	if not Rester.http_validate_method(method) then
		error("Invalid HTTP method: " .. method)
	end

	local final_path = endpoint_template:Format(request_param)

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

--[[
	You know, when the Windows XP source code got leaked,
	when I searched up the word 'bastard' it came in at 18 results.
	We are a men of culture. And fucking suffering.
]]

return Rester
