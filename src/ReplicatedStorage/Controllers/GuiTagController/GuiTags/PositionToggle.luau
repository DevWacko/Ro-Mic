-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packagess --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

local peek = Fusion.peek

-- Main Module --
local PositionToggle = {
	Tag = "PositionToggle"
}

-- Local --
local scopes: { [GuiButton]: Fusion.Scope } = {} 

PositionToggle.taggedObjectAdded = function(taggedObject: GuiButton)
	local scope = Fusion:scoped()
	scopes[taggedObject] = scope
	
	local target: GuiObject = taggedObject:FindFirstChild("Target").Value
	
	local shown: Fusion.Value<boolean> = scope:Value(false)
	scope:Hydrate(target) {
		Position = scope:Spring(scope:Computed(function(use: Fusion.Use)
			return use(shown) and taggedObject:GetAttribute("ShownPosition") or taggedObject:GetAttribute("HiddenPosition")
		end), 25, 0.8)
	}
	
	table.insert(scope, taggedObject.MouseButton1Click:Connect(function()
		shown:set(not peek(shown))
		taggedObject:SetAttribute("ShowingTarget", peek(shown))
	end))
end

PositionToggle.taggedObjectRemoved = function(taggedObject: GuiButton)
	local scope = scopes[taggedObject]
	if scope then
		scope:doCleanup()
		scopes[taggedObject] = nil
	end
end

return PositionToggle