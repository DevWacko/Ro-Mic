-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

-- Main Module --
local MenuClose = {
	Tag = "MenuClose"
}

-- Local --
local scopes: { [GuiButton]: Fusion.Scope } = {}

local menuController

MenuClose.init =function()
	menuController = Knit.GetController("MenuController")
end

MenuClose.taggedObjectAdded = function(taggedObject: GuiObject)
	local scope = Fusion:scoped()
	scopes[taggedObject] = scope
	
	table.insert(scope, taggedObject.MouseButton1Click:Connect(function()
		menuController:CloseMenu(taggedObject:GetAttribute("Menu"))
	end))
end

MenuClose.taggedObjectRemoved = function(taggedObject: GuiObject)
	if scopes[taggedObject] then
		scopes[taggedObject]:doCleanup()
		scopes[taggedObject] = nil
	end
end

return MenuClose