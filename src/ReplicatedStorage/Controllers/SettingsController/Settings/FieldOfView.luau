-- Main Module --
local FieldOfView = {}

FieldOfView.valueSet = function(value: any)
	workspace.CurrentCamera.FieldOfView = value
end

return FieldOfView