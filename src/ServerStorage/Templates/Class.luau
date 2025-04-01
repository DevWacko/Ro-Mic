-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Packages --
local Fusion = require(Packages.Fusion)

-- Variables --
local peek = Fusion.peek

-- Class --
local CLASS_NAME = {}
CLASS_NAME.__index = CLASS_NAME
type UsedAs = Fusion.UsedAs
type Self = typeof(CLASS_NAME)
export type Props = {}

function CLASS_NAME.new(props: Props)
	local self = setmetatable({}, CLASS_NAME)
	self:init(props)
	return self
end

function CLASS_NAME:init(props: Props)
	self.scope = Fusion:scoped() :: Fusion.Scope
end

function CLASS_NAME:Destroy()
	self.scope:doCleanup()
end

return CLASS_NAME