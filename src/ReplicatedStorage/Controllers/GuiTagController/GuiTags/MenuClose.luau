-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

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