-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Main Module --
local MODULE_NAME = {
	Tag = "",
}

-- Local --
local service

MODULE_NAME.init = function()
	service = Knit.GetService("InteractingService")
end

MODULE_NAME.taggedObjectAdded = function(taggedObject: Instance)
	
end

MODULE_NAME.taggedObjectRemoved = function(taggedObject: Instance)
	
end

return MODULE_NAME