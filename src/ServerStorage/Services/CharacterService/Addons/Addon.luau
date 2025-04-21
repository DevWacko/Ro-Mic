-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

-- Main Module --
local ADDON_NAME = {}

-- Local --
local tempScopes: { [Model]: Fusion.Scope } = {}

ADDON_NAME.onEventRecieved = function(player: Player, key: string, ...)
	
end

ADDON_NAME.characterAdded = function(char: Model)
	local scope = Fusion:scoped()
	tempScopes[char] = scope
end

ADDON_NAME.characterRemoving = function(char: Model)
	if tempScopes[char] then
		tempScopes[char]:doCleanup()
		tempScopes[char] = nil
	end
end

return ADDON_NAME