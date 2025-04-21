-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Regions = require(ReplicatedStorage:WaitForChild("Source"):FindFirstChild("Data"):FindFirstChild("Player"):FindFirstChild("Regions"))

local function getFlagEmoji(countryCode: string)
	for _, region in Regions do
		if region.Name ~= countryCode then
			continue
		end
		return region.Emoji
	end
end

return getFlagEmoji