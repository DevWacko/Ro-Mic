local Sound = {}
Sound.__index = Sound

export type self = typeof(Sound)

local function CreateInstance(soundTemp: Sound | string | number, properties: { [string]: any })
	local sound: Sound
	if typeof(soundTemp) == "Instance" and soundTemp:IsA("Sound") then
		sound = soundTemp:Clone()
	elseif typeof(soundTemp) == "string" then
		sound = Instance.new("Sound")
		sound.SoundId = soundTemp
	elseif typeof(soundTemp) == "number" then
		sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. tostring(soundTemp)
	end
	assert(sound ~= nil, "Failed when trying to create sound")
	
	for key, value in properties do
		sound[key] = value
	end
	
	return sound
end

function Sound.new(sound: Sound | string | number, parent: Instance?, properties: { [string]: any })
	local self = setmetatable({}, Sound)
	
	self.Sound = CreateInstance(sound, properties or {})
	self.Sound.Parent = parent or workspace
	
	self.Sound.Ended:Once(function()
		self:Destroy()
	end)
	
	return self
end

function Sound:Play()
	self.Sound:Play()
end
function Sound:Stop()
	self.Sound:Stop()
end
function Sound:Pause()
	self.Sound:Pause()
end
function Sound:Resume()
	self.Sound:Resume()
end

function Sound:Destroy()
	self.Sound:Destroy()
end

return Sound
