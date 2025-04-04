-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

-- Main Module --
local Booth = { MenuName = "TextBooth" }

-- Local --
local interactingController
local interactingService
local controller

local scope: Fusion.Scope = Fusion:scoped()

Booth.init = function()
	interactingController = Knit.GetController("InteractingController")
	interactingService = Knit.GetService("InteractingService")
	controller = Knit.GetController("MenuController")
end

local function manageFonts(mainFrame: Frame)
	local fontsDropdownShown: Fusion.Value<boolean> = scope:Value(false)
	
	table.insert(scope, mainFrame.Middle.Fonts.MouseButton1Click:Connect(function()
		fontsDropdownShown:set(not peek(fontsDropdownShown))
	end))
	scope:Hydrate(mainFrame.FontsDropdown) {
		GroupTransparency = scope:Tween(scope:Computed(function(use: Fusion.Use)
			return use(fontsDropdownShown) and 0 or 1
		end), TweenInfo.new(0.5)),
		Size = scope:Spring(scope:Computed(function(use: Fusion.Use)
			return use(fontsDropdownShown) and UDim2.fromScale(0.245, 0.526) or UDim2.fromScale(0.245, 0)
		end), 25, 0.8),
	}
	scope:Hydrate(mainFrame.Middle.Fonts.Arrow.Icon) {
		Rotation = scope:Spring(scope:Computed(function(use: Fusion.Use)
			return use(fontsDropdownShown) and 0 or -90
		end), 25, 0.8)
	}
	
	local fontContents: ScrollingFrame = mainFrame.FontsDropdown.Contents
	local selectedFontButton: Fusion.Value<TextButton> = scope:Value(fontContents:FindFirstChild("Default"))
	
	for _, fontButton: TextButton? in fontContents:GetChildren() do
		if not fontButton:IsA("TextButton") then
			continue
		end
		scope:Hydrate(fontButton) {
			BackgroundColor3 = scope:Tween(scope:Computed(function(use: Fusion.Use)
				return use(selectedFontButton) == fontButton and Color3.fromRGB(215, 224, 244) or Color3.new(1, 1, 1)
			end), TweenInfo.new(0.25)),
			[OnEvent("MouseButton1Down")] = function()
				selectedFontButton:set(fontButton)
			end
		}
	end
end

local function manageColors(mainFrame: Frame)
	local colorPickerShown: Fusion.Value<boolean> = scope:Value(false)
	
	local textAreaFrame: Frame = mainFrame.Middle.TextArea
	local colorsContainer: Frame = textAreaFrame.Colors.Container
	local colorPicker: ImageButton = textAreaFrame.ColorPicker
	
	local selectedColorButton: Fusion.Value<ImageButton> = scope:Value(colorsContainer:FindFirstChild("Default"))
	
	scope:Hydrate(colorPicker) {
		Visible = scope:Computed(function(use: Fusion.Use)
			return not use(colorPickerShown)
		end),
		[OnEvent("MouseButton1Down")] = function()
			colorPickerShown:set(true)
		end,
	}
	scope:Hydrate(colorPicker.Bucket) {
		ImageColor3 = scope:Tween(scope:Computed(function(use: Fusion.Use)
			return use(selectedColorButton).ImageColor3
		end), TweenInfo.new(0.5)),
	}
	scope:Hydrate(textAreaFrame.Colors) {
		GroupTransparency = scope:Tween(scope:Computed(function(use: Fusion.Use)
			return use(colorPickerShown) and 0 or 1
		end), TweenInfo.new(0.5)),
		Size = scope:Spring(scope:Computed(function(use: Fusion.Use)
			return use(colorPickerShown) and UDim2.fromScale(0.463, 0.836) or UDim2.fromScale(0, 0.836)
		end), 25, 0.8),
	}
	
	for _, colorButton: ImageButton? in colorsContainer:GetChildren() do
		if not colorButton:IsA("ImageButton") then
			continue
		end
		scope:Hydrate(colorButton) {
			[OnEvent("MouseButton1Click")] = function()
				print("CLICKED")
				selectedColorButton:set(colorButton)
				colorPickerShown:set(false)
			end
		}
	end
end

Booth.menuLoaded = function(menu: ScreenGui)
	scope:doCleanup()
	
	local mainFrame: Frame = menu.Main
	scope:Hydrate(mainFrame.Side.UnclaimBooth) {
		[OnEvent("MouseButton1Click")] = function()
			interactingService:InteractAttempt("Booths", "Unclaim"):andThen(function(success: boolean?)
				if success then
					controller:CloseMenu(menu)
					interactingController.Interacted:Fire("Booths", "CancelEdit")
				end
			end)
		end,
	}
	
	manageColors(mainFrame)
	manageFonts(mainFrame)
end

return Booth