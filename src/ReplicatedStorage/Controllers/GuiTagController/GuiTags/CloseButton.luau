-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

-- Main Module --
local CloseButton = {
	Tag = "CloseButton"
}

-- Local --
local scopes: { [GuiButton]: Fusion.Scope } = {}

local menuController

CloseButton.init =function()
	menuController = Knit.GetController("MenuController")
end

CloseButton.taggedObjectAdded = function(taggedObject: GuiObject)
	local scope = Fusion:scoped()
	scopes[taggedObject] = scope
	
	table.insert(scope, taggedObject.MouseButton1Click:Connect(function()
		local targetMenuVal: ObjectValue? = taggedObject:FindFirstChild("Menu")
		if not targetMenuVal then
			return
		end
		local menu = targetMenuVal.Value
		if not menu or not menu:IsA("ScreenGui") then
			return
		end
		menuController:CloseMenu(menu)
	end))
end

CloseButton.taggedObjectRemoved = function(taggedObject: GuiObject)
	if scopes[taggedObject] then
		scopes[taggedObject]:doCleanup()
		scopes[taggedObject] = nil
	end
end

return CloseButton