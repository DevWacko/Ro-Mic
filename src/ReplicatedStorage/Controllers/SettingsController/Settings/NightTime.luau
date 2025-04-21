-- Services --
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Main Module --
local NightTime = {}

NightTime.valueSet = function(toggled: boolean)
	TweenService:Create(Lighting, TweenInfo.new(3), {
		ClockTime = if toggled then 0 else 12
	}):Play()
end

return NightTime