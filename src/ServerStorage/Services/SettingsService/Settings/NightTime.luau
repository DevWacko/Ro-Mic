local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Main Module --
local NightTime = {
	PlayerDebounces = {} :: { [Player]: boolean },
	DefaultValue = false,
}

-- Local --
local playerDebounces: { [Player]: boolean } = {}

NightTime.setSettingAttempt = function(player: Player, toggled: boolean, ...)
	local data = { ... }
	
	assert(toggled ~= nil and typeof(toggled) == "boolean", " value was nil or not a boolean")
	
	return true, toggled
end

NightTime.updated = function(player: Player, toggled: boolean)
	NightTime.PlayerDebounces[player] = true
	task.delay(5, function()
		NightTime.PlayerDebounces[player] = false
	end)
end

return NightTime