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

local function submitMessageAttempt(position)
	--service.Interaction:Fire()
	
	return true
end

MessageBoards.init = function()
	service = Knit.GetService("InteractingService")
end

MessageBoards.sentInteractAttempt = function(player: Player, interaction: string, ...)
	if interaction == "SubmitMessageAttempt" then
		return submitMessageAttempt(...)
	end
end

MessageBoards.taggedObjectAdded = function(taggedObject: Instance)
	
end

MessageBoards.taggedObjectRemoved = function(taggedObject: Instance)
	
end

return MessageBoards