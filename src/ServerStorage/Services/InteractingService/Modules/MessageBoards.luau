-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

-- Main Module --
local MessageBoards = {
	Tag = "MessageBoard",
}

-- Local --
local service

local scope: Fusion.Scope

MessageBoards.init = function()
	service = Knit.GetService("InteractingService")
end

MessageBoards.taggedObjectAdded = function(taggedObject: Instance)
	
end

MessageBoards.taggedObjectRemoved = function(taggedObject: Instance)
	
end

return MessageBoards