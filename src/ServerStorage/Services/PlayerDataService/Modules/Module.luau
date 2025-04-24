-- Packages --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Main Module --
local MODULE_NAME = {}

-- Local --
local service

MODULE_NAME.init = function()
	service = Knit.GetService("PlayerDataService")
end

MODULE_NAME.playerProfileLoaded = function(player: Player)
	
end

MODULE_NAME.playerRemoving = function(player: Player)
	
end

return MODULE_NAME