-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Packages --
local Fusion = require(Packages.Fusion)

-- Variables --
local peek = Fusion.peek

-- Class --
local TYPE_NAME = {}
TYPE_NAME.__index = TYPE_NAME
type UsedAs = Fusion.UsedAs
type Self = typeof(TYPE_NAME)
export type Props = {}

function TYPE_NAME.new(...)
	local self = setmetatable({}, TYPE_NAME)
	self:init(...)
	return self
end

function TYPE_NAME:init(obj: GuiObject)
	self.scope = Fusion:scoped() :: Fusion.Scope
end

function TYPE_NAME:Destroy()
	self.scope:doCleanup()
end

return TYPE_NAME