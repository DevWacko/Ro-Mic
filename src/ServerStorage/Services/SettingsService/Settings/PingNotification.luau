-- Main Module --
local TOGGLE_NAME = {
	PlayerDebounces = {} :: { [Player]: boolean },
	DefaultValue = true,
}

TOGGLE_NAME.setSettingAttempt = function(player: Player, toggled: any, ...)
	local data = { ... }
	
	assert(toggled ~= nil and typeof(toggled) == "boolean", " value was nil or not a boolean")
	
	return true, toggled
end

TOGGLE_NAME.updated = function(player: Player, toggled: any)
	TOGGLE_NAME.PlayerDebounces[player] = true
	task.delay(1, function()
		TOGGLE_NAME.PlayerDebounces[player] = false
	end)
	
end

return TOGGLE_NAME