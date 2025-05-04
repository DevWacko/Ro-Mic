local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Resetting = require(script.Resetting)
local Zones = require(script.Zones)
local Jumps = require(script.Jumps)

local Data = require(ReplicatedStorage.Source.Data.Interacting.GlassBridge)

local GlassBridge = {}
GlassBridge.__index = GlassBridge

export type self = typeof(GlassBridge)

function GlassBridge.new(model: Model)
	local self = setmetatable({}, GlassBridge)
	
	self.IsServer, self.IsClient = RunService:IsServer(), RunService:IsClient()
	
	self.Model = model
	
	if self.IsServer then
		self.LocalTweenService = Knit.GetService("LocalTweenService")
		
		self.Trove = Trove.new()
		
		self.PathReset = self.Trove:Add(Signal.new())
		self.Path = {}
		
		self.PlayersInZone = {} :: { [number]: string }
		Zones(self)
		
		Resetting(self)
		Jumps(self)
		
		self:GenerateNewPath()
	end
	
	return self
end

function GlassBridge:GenerateNewPath()
	self.Path = {}
	
	for _, jumpModel: Model in self.Model:FindFirstChild("Jumps"):GetChildren() do
		local jumps: { BasePart } = jumpModel:GetChildren()
		for _, jump in jumps do
			if not jump:GetAttribute("StartColor") then
				jump:SetAttribute("StartColor", jump.Color)
			end
			if Data.SHOW_PATH then
				jump.Color = jump:GetAttribute("StartColor")
			end
		end
		
		local fakes = if #jumps == 1 or Data.CORRECT_PLATFORM_PER_JUMP > #jumps then jumps else {}
		if #fakes == 0 then
			for i=1, Data.CORRECT_PLATFORM_PER_JUMP do
				local selectedJump: BasePart
				repeat
					selectedJump = jumps[math.random(1, #jumps)]
					task.wait()
				until selectedJump ~= nil
				table.insert(fakes, selectedJump)
				
				if Data.SHOW_PATH then
					for _, p in jumps do
						if table.find(fakes, p) then
							continue
						end
						if Data.SHOW_PATH then
							p.Color = Color3.new(0, 1, 0)
						end
					end
				end
			end
		end
		self.Path[jumpModel] = fakes
	end
	self.PathReset:Fire()
end

function GlassBridge:Destroy()
	self.Trove:Destroy()
end

return GlassBridge
