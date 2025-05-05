-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Packages --
local Fusion = require(Packages.Fusion)

-- Variables --
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

-- Class --
local AnimatedButton = {}
AnimatedButton.__index = AnimatedButton
type UsedAs = Fusion.UsedAs
type Self = typeof(AnimatedButton)
export type Props = {}

function AnimatedButton.new(...)
	local self = setmetatable({}, AnimatedButton)
	self:init(...)
	return self
end

function AnimatedButton:init(button: GuiObject)
	self.scope = Fusion:scoped() :: Fusion.Scope
	
	local objectToAnimate: GuiButton = button
	local customAnimatedObject: ObjectValue? = button:FindFirstChild("Animate")
	if customAnimatedObject then
		objectToAnimate = customAnimatedObject.Value
	end
	
	self.startSize = objectToAnimate.Size
	self.size = self.scope:Value(self.startSize) :: Fusion.Value<Udim2>
	self.sizeSpring = self.scope:Spring(self.size, 30, button:GetAttribute("Responsiveness") or 0.8) :: Fusion.Spring
	
	self.scope:Hydrate(objectToAnimate) {
		Size = self.sizeSpring,
	}
	
	local addedSize = button:GetAttribute("AddedSize") or 10
	
	self.scope:Hydrate(button) {
		[OnEvent("MouseEnter")] = function()
			if button:HasTag("Locked") then
				return
			end
			self.size:set(self.startSize + UDim2.fromOffset(addedSize, addedSize))
		end,
		[OnEvent("MouseLeave")] = function()
			if button:HasTag("Locked") then
				return
			end
			self.size:set(self.startSize)
		end,
		[OnEvent("MouseButton1Down")] = function()
			if button:HasTag("Locked") then
				return
			end
			self.size:set(self.startSize - UDim2.fromOffset(addedSize, addedSize))
		end,
		[OnEvent("MouseButton1Up")] = function()
			if button:HasTag("Locked") then
				return
			end
			self.size:set(self.startSize)
		end,
	}
end

function AnimatedButton:Destroy()
	self.scope:doCleanup()
end

return AnimatedButton