-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

-- Main Module --
local Slider = {
	Tag = "Slider"
}

-- Local --
local tempScopes: { [Instance]: Fusion.Scope } = {}

Slider.taggedObjectAdded = function(taggedObject: GuiObject)
	local scope = Fusion:scoped()
	
	local value: Fusion.Value<number> = scope:Value(taggedObject:GetAttribute("Value"))
	local min: Fusion.Value<number> = scope:Value(taggedObject:GetAttribute("Min"))
	local max: Fusion.Value<number> = scope:Value(taggedObject:GetAttribute("Max"))
	
	local handle: GuiButton = taggedObject:FindFirstChild("Handle")
	
	local handleStartY = handle.Position.Y
	local handlePos: Fusion.Value<UDim2> = scope:Value(UDim2.new(peek(value) / peek(max), 0, handleStartY))
	
	local holding: Fusion.Value<boolean> = scope:Value(false)
	local holdingCon: RBXScriptConnection?
	scope:Observer(holding):onChange(function()
		if peek(holding) then
			holdingCon = RunService.RenderStepped:Connect(function()
				
			end)
		else
			if holdingCon then
				holdingCon:Disconnect()
				holdingCon = nil
			end
		end
	end)
	
	scope:Hydrate(handle) {
		Position = handlePos,
		[OnEvent("MouseButton1Down")] = function()
			holding:set(true)
		end,
		[OnEvent("MouseButton1Up")] = function()
			holding:set(false)
		end,
	}
	
	tempScopes[taggedObject] = scope
end

Slider.taggedObjectRemoved = function(taggedObject: GuiObject)
	local scope = tempScopes[taggedObject]
	if scope then
		scope:doCleanup()
		tempScopes[taggedObject] = nil
	end
end

return Slider