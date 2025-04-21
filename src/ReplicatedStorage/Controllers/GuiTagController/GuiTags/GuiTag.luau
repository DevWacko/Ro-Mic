-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages --
local Fusion = require(ReplicatedStorage:WaitForChild("ExPackages"):FindFirstChild("Fusion"))

-- Main Module --
local GUI_TAG_NAME = {
	Tag = ""
}

-- Local --
local tempScopes: { [GuiObject]: Fusion.Scope } = {}

GUI_TAG_NAME.taggedObjectAdded = function(taggedObject: GuiObject)
	local scope = Fusion:scoped()
	tempScopes[taggedObject] = scope
end

GUI_TAG_NAME.taggedObjectRemoved = function(taggedObject: GuiObject)
	local scope = tempScopes[taggedObject]
	if scope then
		scope:doCleanup()
		tempScopes[taggedObject] = nil
	end
end

return GUI_TAG_NAME