-- Main Module --
local AllowAvatarCloning = {
	DefaultValue = false,
}

AllowAvatarCloning.setSettingAttempt = function(player: Player, toggled: any, ...)
	local data = { ... }
	
	assert(toggled ~= nil and typeof(toggled) == "boolean", " value was nil or not a boolean")
	
	return true, toggled
end

AllowAvatarCloning.updated = function(player: Player, toggled: any)
	
end

return AllowAvatarCloning