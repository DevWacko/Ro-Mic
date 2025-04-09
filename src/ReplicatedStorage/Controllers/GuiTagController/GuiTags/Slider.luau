-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Modules --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

-- Main Module --
local Slider = {
	Tag = "Slider"
}

-- Local --
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local tempScopes: { [Instance]: Fusion.Scope } = {}

Slider.taggedObjectAdded = function(taggedObject: GuiObject)
	local scope = Fusion:scoped()
	
	local value: Fusion.Value<number> = scope:Value(taggedObject:GetAttribute("Value"))
	
	local handle: GuiButton = taggedObject:FindFirstChild("Handle")
	
	local handleStartY = handle.Position.Y
	local startX = UDim.new(peek(taggedObject:GetAttribute("Value")) / peek(taggedObject:GetAttribute("Max")))
	local handlePos: Fusion.Value<UDim2> = scope:Value(UDim2.new(startX, handleStartY))
	
	local fill: GuiObject? = taggedObject:FindFirstChild("Fill")
	local fillSize: Fusion.Value<UDim2>? = fill and scope:Value(UDim2.fromScale(startX, 1)) or nil
	
	local progress = peek(taggedObject:GetAttribute("Value"))
	
	local function setSize(value: number)
		progress = peek(taggedObject:GetAttribute("Max")) * value
		
		handlePos:set(UDim2.new(UDim.new(value, 0), handleStartY))
		fillSize:set(UDim2.new(value, 0, 1, 0))
	end
	
	scope:Observer(value):onBind(function()
		setSize(peek(value))
	end)
	
	local holding: Fusion.Value<boolean> = scope:Value(false)
	local holdingCon: RBXScriptConnection?
	scope:Observer(holding):onChange(function()
		if peek(holding) then
			holdingCon = RunService.RenderStepped:Connect(function()
				local sliderAbsPos = taggedObject.AbsolutePosition.X
				local sliderWidth = taggedObject.AbsoluteSize.X
				
				local relativeX = math.clamp((mouse.X - sliderAbsPos) / sliderWidth, 0, 1)
				value:set(relativeX)
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
	}
	table.insert(scope, UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holding:set(false)
			taggedObject:SetAttribute("Value", progress)
		end
	end))
	
	table.insert(scope, taggedObject:GetAttributeChangedSignal("Value"):Connect(function()
		setSize(taggedObject:GetAttribute("Value"))
	end))
	
	if fill then
		scope:Hydrate(fill) {
			Size = fillSize,
		}
	end
	
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