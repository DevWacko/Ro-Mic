-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Knit = require(ReplicatedStorage.ExPackages.Knit)

-- Main Module --
local MODULE_NAME = {
	Tag = "",
}

-- Local --
local controller

MODULE_NAME.init = function()
	controller = Knit.GetController("InteractingController")
end

MODULE_NAME.taggedObjectAdded = function(taggedObject: Instance)
	
end

MODULE_NAME.taggedObjectRemoved = function(taggedObject: Instance)
	
end

return MODULE_NAME