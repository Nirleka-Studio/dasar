-- Rester.lua
-- NirlekaDev
-- April 15, 2025

local CharMap = require("../variant/CharMap")
local HttpPromise = require("./HttpPromise")

local DEFAULT_MEDIA_TYPE = "application/vnd.github.v3+json"
local URL_GITHUB_API = "https://api.github.com"
local URL_GITHUB_CONTENTS = `{URL_GITHUB_API}/repos/%s/%s/contents/%s`
local URL_GITHUB_TREE = `{URL_GITHUB_API}/repos/%s/%s/git/trees/%s?recursive=1`
local URL_GITHUB_RATELIMIT = `{URL_GITHUB_API}/rate_limit`
local HTTP_VALID_METHODS = {
	["GET"] = true,
	["POST"] = true,
	["PATCH"] = true,
	["PUT"] = true,
	["DELETE"] = true
}

--[=[
	@class Rester
]=]
local Rester = {}
Rester.__index = Rester

function Rester.new(arr: { [string]: any })
	return setmetatable(arr, Rester)
end

--[=[
	TODO: Add doc
]=]
function Rester.get_content(request_arr: { [string]: any })
	assert(type(request_arr) == "table", "`request_arr` must be a table")

	local owner = request_arr.owner or error("Missing required parameter: owner")
	local repo = request_arr.repo or error("Missing required parameter: repo")
	local path = request_arr.path or error("Missing required parameter: path")

	local url = URL_GITHUB_CONTENTS:format(owner, repo, path)

	return Rester.request(url, {
		["Headers"] = request_arr.headers or nil
	})
end

--[=[
	This is fucked up hack.
	Doesn't efficiently get the descendants of the given path.
	Fetches the full tree and filters it. Which is a terrible way for doing it.
]=]
function Rester.get_descendants(request_arr)
	assert(type(request_arr) == "table", "`request_arr` must be a table")

	local path = request_arr.path or error("Missing required parameter: path")

	return Rester.get_tree_recursive(request_arr):andThen(function(response)
		local tree = response.tree or error("Invalid tree response structure")
		local prefix = path:gsub("^/", ""):gsub("/$", "") .. "/"

		local descendants = {}

		for _, entry in ipairs(tree) do
			if entry.path:sub(1, #prefix) == prefix then
				table.insert(descendants, entry)
			end
		end

		return descendants
	end)
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
	return HttpPromise.request({
		Url = URL_GITHUB_RATELIMIT,
		Method = "GET",
		Headers = {
			["Accept"] = DEFAULT_MEDIA_TYPE
		}
	})
end

--[=[
	TODO: Add doc
]=]
function Rester.get_tree_recursive(request_arr)
	assert(type(request_arr) == "table", "`request_arr` must be a table")

	local owner = request_arr.owner or error("Missing required parameter: owner")
	local repo = request_arr.repo or error("Missing required parameter: repo")
	local path = request_arr.branch or error("Missing required parameter: branch")

	local url = URL_GITHUB_TREE:format(owner, repo, path)

	return Rester.request(url, {
		["Headers"] = request_arr.headers or nil
	})
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

	```lua
	Rester.request("POST /repos/{owner}/{repo}/{path}", {
		owner = "Nirleka-Studio",
		repo = "dasar",
		path = ""
		headers = {
			["Accept"] = "application/vnd.github+json"
		}
	})
	```
]=]
function Rester.request(base_url: string, request_arr: { [string]: any }?)
	assert(type(base_url) == "string", "`base_url` must be a string")
	assert(type(request_arr) == "table", "`request_arr` must be a table")

	base_url = CharMap(base_url)
	local segments = base_url:Split(" ")
	local method = segments[1]:upper()
	local endpoint_template = CharMap(segments[2])

	if not Rester.http_validate_method(method) then
		error("Invalid HTTP method: " .. method)
	end

	local final_path = endpoint_template:gsub("{(.-)}", function(key)
		local value = request_arr[key]
		if not value then
			error("Missing required parameter: " .. key)
		end
		return tostring(value)
	end)

	local headers = {
		["Accept"] = request_arr.accept or DEFAULT_MEDIA_TYPE,
	}

	if request_arr.headers then
		for key, value in pairs(request_arr.headers) do
			headers[key] = value
		end
	end

	local url = URL_GITHUB_API .. "/" .. final_path

	return HttpPromise.request({
		Url = url,
		Method = method,
		Headers = headers
	})
end

return Rester
