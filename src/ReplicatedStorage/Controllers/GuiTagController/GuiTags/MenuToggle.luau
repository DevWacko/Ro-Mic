-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

local peek = Fusion.peek

-- Main Module --
local MenuToggle = {
	Tag = "MenuToggle"
}

-- Local --
local scopes: { [GuiButton]: Fusion.Scope } = {}

local menuController

MenuToggle.init =function()
	menuController = Knit.GetController("MenuController")
end

MenuToggle.taggedObjectAdded = function(taggedObject: GuiObject)
	local scope = Fusion:scoped()
	scopes[taggedObject] = scope
	
	table.insert(scope, taggedObject.MouseButton1Click:Connect(function()
		local menuName = taggedObject:GetAttribute("Menu")
		
		local currentMenu: ScreenGui? = menuController:GetCurrentMenu()
		local isOpen = currentMenu and currentMenu.Name == menuName
		if isOpen then
			menuController:CloseMenu(menuName)
		elseif not isOpen then
			menuController:SetMenu(menuName)
		end
	end))
end

MenuToggle.taggedObjectRemoved = function(taggedObject: GuiObject)
	if scopes[taggedObject] then
		scopes[taggedObject]:doCleanup()
		scopes[taggedObject] = nil
	end
end

return MenuToggle