-- CameraSocket.lua
-- Nirleka Dev
-- November 28, 2024

--[=[
	@class CameraSocket

	A camera socket is a predefined point in space with attirbutes like CFrames and FieldOfView.
	Used to facilitate camera transitions.
]=]
local CameraSocket = {}
CameraSocket.__index = CameraSocket

--[=[
	Constructs a new CameraSocket instance.
]=]
function CameraSocket.new(name: string, cframe: CFrame, fov: number)
	return setmetatable({
		name = name,
		cframe = cframe,
		fov = fov
	}, CameraSocket)
end

--[=[
	Constructs a new CameraSocket instance from a BasePart,
	field of view will be taken from the BasePart's "fov" attribute,
	or defaults to 70.
]=]
function CameraSocket.from(part: BasePart)
	if typeof(part) == "Instance" and not part:IsA("BasePart") then
		return nil
	end

	local fov = tonumber(part:GetAttribute("fov")) or 70
	return CameraSocket.new(part.Name, part.CFrame, fov)
end

--[=[
	Returns an array of CameraSockets from the array of parts.
]=]
function CameraSocket.fromArray(array: { [number] : BasePart })
	if type(array) ~= "table" or #array == 0 then
		return nil
	end

	local sockets = {}

	for _, part in ipairs(array) do
		local new_socket = CameraSocket.from(part)
		if not new_socket then
			continue
		end

		sockets[ #sockets + 1 ] = new_socket
	end

	return sockets
end

return CameraSocket