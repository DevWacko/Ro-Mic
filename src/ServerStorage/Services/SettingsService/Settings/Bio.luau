-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Modules --
local RightMenuData = require(ReplicatedStorage:FindFirstChild("Source"):FindFirstChild("Data"):FindFirstChild("Gui"):FindFirstChild("RightMenu"))

local filterString = require(ServerStorage:FindFirstChild("Source"):FindFirstChild("Utils"):FindFirstChild("filterString"))

-- Main Module --
local Bio = {
	DefaultValue = "",
}

Bio.setSettingAttempt = function(player: Player, value: any, ...)
	local data = { ... }
	
	local maxChars = RightMenuData.Profile.MAX_BIO_CHARACTERS
	
	assert(type(value) == "string", "Bio must be a string")
	if string.len(value) > maxChars then
		warn(`Bio must be less than {maxChars} characters`)
		return false
	end
	value = filterString(player, value)
	print(value)
	
	return true, value
end

Bio.updated = function(player: Player, value: any)
	
end

return Bio