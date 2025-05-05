-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage:WaitForChild("Packages")

-- Modules --
local Fusion = require(Packages:FindFirstChild("Fusion"))
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(Packages:FindFirstChild("Knit"))

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local BodyScalesData = require(ReplicatedStorage.Source.Data.Character.BodyScales)

-- Local --
local characterService

local scope: Fusion.Scope
local pickedColor: Fusion.Value<Color3>
local trove = Trove.new()

local modificationsFrame: Frame
local optionsFrame: Frame

local player = Players.LocalPlayer
local char: Model
local hum: Humanoid

local function manageColorPicking()
	local colorButtons: { [number]: ImageButton } = {}
	for _, colorButton: ImageButton? in modificationsFrame:FindFirstChild("Colors"):FindFirstChild("Contents"):GetChildren() do
		if not colorButton:IsA("ImageButton") then
			continue
		end
		table.insert(colorButtons, colorButton)
	end
	
	local colorPickerButton: ImageButton = modificationsFrame:FindFirstChild("ColorPicker")
	pickedColor:set(colorButtons[math.random(1, #colorButtons)].ImageColor3)
	scope:Hydrate(colorPickerButton:FindFirstChild("Bucket")) {
		ImageColor3 = scope:Tween(pickedColor, TweenInfo.new(0.25)),
	}
	
	for _, colorButton: ImageButton in colorButtons do
		table.insert(scope, colorButton.MouseButton1Click:Connect(function()
			pickedColor:set(colorButton.ImageColor3)
			colorPickerButton:SetAttribute("TargetShown", false)
		end))
	end
end

local function manageColoring()
	local bodyColors: BodyColors = char:WaitForChild("Body Colors")
	local colorValues: { [string]: Fusion.Value<string> } = {}
	
	trove:Add(bodyColors.Changed:Connect(function(property: string)
		if colorValues[property] then
			colorValues[property]:set(bodyColors[property])
		end
	end))
	
	for _, limbButton: ImageButton? in optionsFrame:FindFirstChild("Limbs"):GetChildren() do
		if not limbButton:IsA("ImageButton") then
			continue
		end
		
		local color: Fusion.Value<Color3?> = scope:Value(bodyColors[limbButton.Name .. "Color3"])
		scope:Observer(color):onChange(function()
			characterService:SendAddonEventAttempt("BodyColors", "SetLimbColor", limbButton.Name, peek(color))
		end)
		colorValues[limbButton.Name .. "Color3"] = color
		
		scope:Hydrate(limbButton) {
			ImageColor3 = scope:Tween(color, TweenInfo.new(0.25)),
			[OnEvent("MouseButton1Click")] = function()
				color:set(peek(pickedColor))
			end,
		}
	end
end

local function manageScale()
	local sliders: { [number]: Frame } = {}
	for _, scaleSettingFrame in optionsFrame:FindFirstChild("Scale"):GetChildren() do
		if not scaleSettingFrame:IsA("Frame") then
			continue
		end
		table.insert(sliders, scaleSettingFrame:FindFirstChild("Slider"))
	end
	for _, slider in sliders do
		local range = BodyScalesData.ScalingRanges[slider.Parent.Name]
		slider:SetAttribute("Min", range.MIN)
		slider:SetAttribute("Max", range.MAX)
		local val: NumberValue = hum:FindFirstChild(slider.Parent.Name)
		trove:Add(val.Changed:Connect(function(newScale)
			slider:SetAttribute("Value", newScale)
		end))
		slider:SetAttribute("Value", val.Value)
		table.insert(scope, slider:GetAttributeChangedSignal("Value"):Connect(function()
			characterService:SendAddonEventAttempt("BodyScales", "SetBodyTypeScale", slider.Parent.Name, slider:GetAttribute("Value"))
		end))
	end
end

local function manageReset()
	local resetButton: ImageButton = modificationsFrame:FindFirstChild("Reset")
	table.insert(scope, resetButton.MouseButton1Click:Connect(function()
		characterService:SendAddonEventAttempt("BodyScales", "ResetBodyScale")
		characterService:SendAddonEventAttempt("BodyColors", "ResetBodyColors")
	end))
end

local function manageModificationFrame(tempScope: Fusion.Scope, mainFrame: Frame)
	characterService = Knit.GetService("CharacterService")
	
	char = player.Character or player.CharacterAppearanceLoaded:Wait()
	hum = char:WaitForChild("Humanoid")
	
	scope = tempScope
	pickedColor = scope:Value()
	
	table.insert(scope, player.CharacterAdded:Connect(function()
		trove:Clean()
	end))
	table.insert(scope, trove)
	
	modificationsFrame = mainFrame:FindFirstChild("Modifications")
	optionsFrame = modificationsFrame:FindFirstChild("Options")
	
	manageColorPicking()
	manageColoring()
	
	manageScale()
	manageReset()
end

return manageModificationFrame