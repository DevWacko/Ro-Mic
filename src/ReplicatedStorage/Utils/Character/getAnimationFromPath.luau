-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Animations = ReplicatedStorage.Assets.Animations

local function getAnimationFromPath(path: string)
	local animation: Animation = Animations
	for _, pathPoint in string.split(path, "/") do
		animation = animation:FindFirstChild(pathPoint)
		if animation == nil then
			warn("Animation not found at path: " .. path)
		end
	end
	return animation
end

return getAnimationFromPath