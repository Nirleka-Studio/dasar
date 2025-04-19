-- Provider.lua
-- NirlekaDev
-- January 19, 2025

local ContentProvider = game:GetService("ContentProvider")
local Promise = require("../modules/thirdparty/Promise")

--[=[
	@class Provider

	Wraps the ContentProvider service with Promise.
	With additional useful methods.
]=]
local Provider = {}

function Provider._preload_async(assets)
	
end

function Provider.preload_async(assets: Instance | string | { [any] : Instance | string })
	return Promise.try(Provider._preload_async, assets)
end

function Provider.wait_for_game_load()
	return Promise.new()
end

return Provider
