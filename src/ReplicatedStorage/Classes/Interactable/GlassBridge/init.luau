local RunService = game:GetService("RunService")

local Jumps = require(script.Jumps)

local GlassBridge = {}
GlassBridge.__index = GlassBridge

export type self = typeof(GlassBridge)

function GlassBridge.new(model: Model)
	local self = setmetatable({}, GlassBridge)
	
	self.IsServer, self.IsClient = RunService:IsServer(), RunService:IsClient()
	Jumps()
	
	return self
end

function GlassBridge:Destroy()
	
end

return GlassBridge
