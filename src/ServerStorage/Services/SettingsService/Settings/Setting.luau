-- Main Module --
local SETTING_NAME = {
	PlayerDebounces = {} :: { [Player]: boolean },
	DefaultValue = nil,
}

SETTING_NAME.setSettingAttempt = function(player: Player, value: any, ...)
	local data = { ... }
	
	return true, value
end

SETTING_NAME.updated = function(player: Player, value: any)
	SETTING_NAME.PlayerDebounces[player] = true
	task.delay(1, function()
		SETTING_NAME.PlayerDebounces[player] = false
	end)
	
end

return SETTING_NAME