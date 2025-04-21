local Workspace = game:GetService("Workspace")
-- Constants --
local MIN_FOV = 0
local MAX_FOV = 120

-- Main Module --
local FieldOfView = {
	DefaultValue = Workspace.CurrentCamera.FieldOfView,
}

FieldOfView.setSettingAttempt = function(player: Player, value: any, ...)
	local data = { ... }
	
	value = math.clamp(value, MIN_FOV, MAX_FOV)
	
	return true, value
end

return FieldOfView