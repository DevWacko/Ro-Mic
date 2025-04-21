-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Packages --
local Fusion = require(ReplicatedStorage:WaitForChild("ExPackages"):FindFirstChild("Fusion"))

local peek = Fusion.peek

-- Main Module --
local Dropdown = {
	Tag = "Dropdown"
}

-- Local --
local tempScopes: { [GuiButton]: Fusion.Scope } = {}

Dropdown.taggedObjectAdded = function(taggedObject: GuiButton)
	local scope = Fusion:scoped()
	tempScopes[taggedObject] = scope
	
	local targetVal: ObjectValue = taggedObject:FindFirstChild("Target")
	local target: GuiObject = targetVal.Value
	
	local shown: Fusion.Value<boolean> = scope:Value(false)
	scope:Observer(shown):onBind(function()
		local target: GuiObject? = target
		if not target or not target:IsA("CanvasGroup") then
			return
		end
		
		TweenService:Create(target, TweenInfo.new(0.2), {
			GroupTransparency = if peek(shown) then 0 else 1
		}):Play()
	end)
	
	scope:Hydrate(target) {
		Visible = scope:Computed(function(use: Fusion.Use)
			return if taggedObject:GetAttribute("IgnoreAnimation") then use(shown) else true
		end),
		Size = scope:Spring(scope:Computed(function(use: Fusion.Use)
			return if taggedObject:GetAttribute("IgnoreAnimation") then taggedObject.Size else
				(use(shown) and taggedObject:GetAttribute("ShownSize") or taggedObject:GetAttribute("HiddenSize"))
		end), 25, 0.8),
	}
	
	local arrow: GuiObject? = taggedObject:FindFirstChild("Arrow")
	if arrow then
		scope:Hydrate(arrow) {
			Rotation = scope:Spring(scope:Computed(function(use: Fusion.Use)
				return use(shown) and 0 or -90
			end), 25, 0.8),
		}
	end
	
	table.insert(scope, taggedObject.MouseButton1Click:Connect(function()
		shown:set(not peek(shown))
		taggedObject:SetAttribute("TargetShown", peek(shown))
	end))
	table.insert(scope, taggedObject:GetAttributeChangedSignal("TargetShown"):Connect(function()
		shown:set(taggedObject:GetAttribute("TargetShown"))
	end))
	
	local InSelection = false
	
	table.insert(scope, target.MouseEnter:Connect(function() InSelection = true end))
	table.insert(scope, target.MouseLeave:Connect(function() InSelection = false end))
	
	table.insert(scope, UserInputService.InputBegan:Connect(function(input)
		if target.Visible and not InSelection and input.UserInputType == Enum.UserInputType.MouseButton1 then
			shown:set(false)
			taggedObject:SetAttribute("TargetShown", false)
		end
	end))
end

Dropdown.taggedObjectRemoved = function(taggedObject: GuiButton)
	local scope = tempScopes[taggedObject]
	if scope then
		scope:doCleanup()
		tempScopes[taggedObject] = nil
	end
end

return Dropdown