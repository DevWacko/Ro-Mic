-- Services --
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Modules --
local Fusion = require(ReplicatedStorage.Packages.Fusion)

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
	
	local handle: GuiButton = taggedObject:FindFirstChild("Handle")
	local fill: GuiObject? = taggedObject:FindFirstChild("Fill")
	
	local getMin, getMax = function()
		return taggedObject:GetAttribute("Min") or 0
	end, function()
		return taggedObject:GetAttribute("Max") or 1
	end
	
	local function normalizeValue(value)
		local min = getMin()
		return (value - min) / (getMax() - min)
	end
	
	local startMin, startMax = getMin(), getMax()
	local startValue = taggedObject:GetAttribute("Value") or ((startMin + startMax) / 2)
	
	local steppedValue = startValue
	local normalized = (peek(steppedValue) - startMin) / (startMax - startMin)
	
	local function updateHandleAndFill(input)
		local sliderAbsPos = taggedObject.AbsolutePosition.X
		local sliderWidth = taggedObject.AbsoluteSize.X
	
		local relativeX = math.clamp((mouse.X - sliderAbsPos) / sliderWidth, 0, 1)
		
		local min = getMin()
		local max = getMax()
		local rawValue = min + (max - min) * relativeX
	
		steppedValue = math.floor(rawValue * 100 + 0.5) / 100
		normalized = normalizeValue(steppedValue)
	
		handle.Position = UDim2.new(normalized, 0, 0.5, 0)
		
		if fill then
			fill.Size = UDim2.new(normalized, 0, 1, 0)
		end
	end
	local function updateFromValue(value)
		local min, max = getMin(), getMax()
		
		local clampedNormalized = math.clamp((value - min) / (max - min), 0, 1)
		
		handle.Position = UDim2.new(clampedNormalized, 0, 0.5, 0)
		
		if fill then
			fill.Size = UDim2.new(clampedNormalized, 0, 1, 0)
		end
	end
	local function updateValueTextAttempt()
		local valueLabelVal: ObjectValue? = taggedObject:FindFirstChild("ValueLabel")
		if not valueLabelVal then
			return
		end
		local valueLabel: GuiLabel? = valueLabelVal.Value
		if not valueLabel then
			return
		end
		
		local textType = taggedObject:GetAttribute("ValueTextType")
		local value = taggedObject:GetAttribute("Value")
		
		local text = ""
		if textType == "Percentage" then
			text = tostring(math.floor(normalizeValue(value) * 100)) .. "%"
		end
		valueLabel.Text = text
	end
	
	local updateCon: RBXScriptConnection?
	table.insert(scope, handle.MouseButton1Down:Connect(function()
		if updateCon then
			updateCon:Disconnect()
			updateCon = nil
		end
		updateCon = RunService.RenderStepped:Connect(updateHandleAndFill)
	end))
	table.insert(scope, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and updateCon then
			updateCon:Disconnect()
			updateCon = nil
			
			taggedObject:SetAttribute("Value", steppedValue)
		end
	end))
	
	local userInput = taggedObject:FindFirstChild("UserInput")
	local function setUserInputText(value: number)
		if not userInput then
			return
		end
		local inputLabel: TextBox = userInput.Value
		inputLabel.Text = math.clamp(value, getMin(), getMax())
	end
	if userInput then
		local inputLabel: TextBox = userInput.Value
		
		table.insert(scope, inputLabel.FocusLost:Connect(function()
			local value = tonumber(inputLabel.Text)
			if not value then
				setUserInputText(math.floor(taggedObject:GetAttribute("Value") or startValue))
				return
			end
			
			local clampedValue = math.clamp(value, getMin(), getMax())
			taggedObject:SetAttribute("Value", clampedValue)
			setUserInputText(clampedValue)
		end))
	end
	setUserInputText(peek(steppedValue))
	
	table.insert(scope, taggedObject:GetAttributeChangedSignal("Value"):Connect(function()
		local value = taggedObject:GetAttribute("Value")
		updateFromValue(value)
		setUserInputText(math.floor(value))
		
		updateValueTextAttempt()
	end))
	updateValueTextAttempt()
	
	local reset: ObjectValue? = taggedObject:FindFirstChild("Reset")
	if reset then
		table.insert(scope, reset.Value.MouseButton1Click:Connect(function()
			taggedObject:SetAttribute("Value", startValue)
		end))
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