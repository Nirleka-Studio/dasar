-- Rester.lua
-- NirlekaDev
-- April 15, 2025

local CharMap = require("../variant/CharMap")
local HttpPromise = require("./HttpPromise")

local DEFAULT_MEDIA_TYPE = "application/vnd.github.v3+json"
local URL_GITHUB_API = "https://api.github.com"
local URL_GITHUB_CONTENTS = `/repos/%s/%s/contents/%s`
local URL_GITHUB_TREE = `/repos/%s/%s/git/trees/%s?recursive=1`
local URL_GITHUB_RATELIMIT = `/rate_limit`
local HTTP_VALID_METHODS = {
	["GET"] = true,
	["POST"] = true,
	["PATCH"] = true,
	["PUT"] = true,
	["DELETE"] = true
}

--[=[
	@class Rester

	Makes your life less shittier (but still shit) when interacting with the Github REST API.
	Based on the already confusing "Octokit.js" and the dogshit of a documentation.

	Rester? So thats why. It rests my mental state 6 feet under.
]=]
local Rester = {}
Rester.__index = Rester

function Rester.new(arr: { [string]: any })
	return setmetatable(arr, Rester)
end

--[=[
	TODO: Im too mentally fucked to write this shitty doc.
]=]
function Rester.get_content(request_arr: { [string]: any })
	--[[
		"A function that basically does the same shit by calling another function
		but shortens the operation so you can be a lazy little shit is a good function."
			- The Founder, 2025
	]]
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
	I swear to whatever god that doesnt exists, if the goddamn solution to get the descendants
	of a goddamn folder, file, or whatever bullshit within a Github repository is by fucking fetching
	the contents of the file one by fucking one, draining our limit quota, THEN IM FUCKING

	This function retrieves the contents and descendant files and folder within the specified path.
]=]
function Rester.get_descendants(request_arr)
	-- removed cuz github is a piece of shit
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
	local path = request_arr.path or error("Missing required parameter: branch")

	local url = "GET "..URL_GITHUB_TREE:format(owner, repo, path)

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

	local url = URL_GITHUB_API .. "/" .. endpoint_template:gsub("^/", "")

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
