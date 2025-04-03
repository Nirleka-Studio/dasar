-- ButtonClass.lua
-- NirlekaDev
-- January 5, 2025

--[=[
	@class ButtonClass

	A simple class for a button that uses Input.
]=]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local Input = require("Input")
local Maid = require("Maid")
local Signal = require("Signal")

local ButtonClass = {}
ButtonClass.__index = ButtonClass

function ButtonClass.new(parent: Instance)
	local self = setmetatable({}, ButtonClass)

	self._data = {
		click_detector = Instance.new("ClickDetector", parent),
		is_active = true,
		is_hovered = false,
		parent = parent,
	} -- Contains the actual data
	self._maid = Maid.new()

	self.MouseButton1Click = Signal.new()
	self.MouseButton1Lift = Signal.new()
	self.MouseHover = Signal.new()
	self.MouseHoverRaw = Signal.new()
	self.MouseHoverInvalid = Signal.new()
	self.MouseLeave = Signal.new()

	self:_bind_methods()

	return self
end

function ButtonClass:__index(index)
	if ButtonClass[index] then
		return ButtonClass[index]
	elseif self[index] then
		return self[index]
	else
		return self._data[index]
	end
end

function ButtonClass:__newindex(index, value)
	self._data[index] = value

	if index == "is_active" then
		if not value then
			self.MouseLeave:Fire()
		else
			if self.is_hovered then
				self.MouseHover:Fire()
			end
		end
	end
end

function ButtonClass:_bind_methods()
	local clickDetector = self.click_detector

	self._maid:GiveTasksArray({
		self.MouseButton1Click,
		self.MouseButton1Lift,
		clickDetector,
		clickDetector.MouseHoverEnter:Connect(function()
			self:OnHover()
		end),
		clickDetector.MouseHoverLeave:Connect(function()
			self:OnLeave()
		end),
		Input.ListenInputPressed(Enum.UserInputType.MouseButton1):Connect(function()
			if self._mouseHovered then
				self.MouseButton1Click:Fire()
			end
		end),
		Input.ListenInputReleased(Enum.UserInputType.MouseButton1):Connect(function()
			self.MouseButton1Lift:Fire()
		end)
	})
end

function ButtonClass:OnHover()
	self.MouseHoverRaw:Fire()

	self.is_hovered = true

	if self.is_active and Input.IsInputEnabled() then
		self.MouseHover:Fire()
	else
		self.MouseHoverInvalid:Fire()
	end
end

function ButtonClass:OnLeave()
	self.is_hovered = false
	self.MouseLeave:Fire()
end

function ButtonClass:Destroy()
	if self.is_hovered then
		self.MouseLeave:Fire()
	end
	self._maid:DoCleaning()
	setmetatable(self, nil)
end

return ButtonClass