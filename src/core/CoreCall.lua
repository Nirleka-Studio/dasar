local RunService = game:GetService('RunService')

local MAX_RETRIES = 8

--[=[
	@class CoreCall
]=]
local CoreCall = {}

function CoreCall._ready()
	CoreCall.Call('StarterGui', 'SetCoreGuiEnabled', Enum.CoreGuiType.All, false)
end

function CoreCall.Call(service: string, method: string, ...)
	local result = {}
	service = game:GetService(service)
	for retries = 1, MAX_RETRIES do
		result = {pcall(service[method], service, ...)}
		if result[1] then
			break
		end
		RunService.Stepped:Wait()
	end
	return unpack(result)
end

return CoreCall