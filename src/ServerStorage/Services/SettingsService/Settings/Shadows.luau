-- Main Module --
local Shadows = {
	PlayerDebounces = {} :: { [Player]: boolean },
	DefaultValue = true,
}

Shadows.setSettingAttempt = function(player: Player, toggled: any, ...)
	local data = { ... }
	
	assert(toggled ~= nil and typeof(toggled) == "boolean", " value was nil or not a boolean")
	print("SHADOWS", toggled)
	return true, toggled
end

Shadows.updated = function(player: Player, toggled: any)
	Shadows.PlayerDebounces[player] = true
	task.delay(1, function()
		Shadows.PlayerDebounces[player] = false
	end)
end

return Shadows