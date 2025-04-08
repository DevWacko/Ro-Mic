-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local OnEvent, OnChange = Fusion.OnEvent, Fusion.OnChange
local peek = Fusion.peek

-- Main Module --
local Booth = { MenuName = "TextBooth" }

-- Local --
local interactingController
local interactingService
local controller

local scope: Fusion.Scope = Fusion:scoped()

local weights = {
	[1] = Enum.FontWeight.Regular,
	[2] = Enum.FontWeight.Bold,
}
local styles = {
	[1] = Enum.FontStyle.Normal,
	[2] = Enum.FontStyle.Italic,
}
local strokeThicknessRange = {
	[1] = 0,
	[2] = 3,
}

Booth.init = function()
	interactingController = Knit.GetController("InteractingController")
	interactingService = Knit.GetService("InteractingService")
	controller = Knit.GetController("MenuController")
end

local function manageFonts(mainFrame: Frame)
	local fontsDropdownShown: Fusion.Value<boolean> = scope:Value(false)
	
	local fontContents: ScrollingFrame = mainFrame.FontsDropdown.Contents
	local selectedFontButton: Fusion.Value<TextButton> = scope:Value(fontContents:FindFirstChild("Default"))
	
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
	scope:Hydrate(mainFrame:FindFirstChild("Middle"):FindFirstChild("Fonts"):FindFirstChild("SelectedFont")) {
		Text = scope:Computed(function(use: Fusion.Use)
			return use(selectedFontButton).Text
		end),
		FontFace = scope:Computed(function(use: Fusion.Use)
			return use(selectedFontButton).FontFace
		end),
	}
	
	local fontFace: Fusion.Value<Font> = scope:Value(Font.new(peek(selectedFontButton).FontFace.Family))
	
	local textEditButtonsFrame: Frame = mainFrame.Side.TextEditButtons
	
	local weight: Fusion.Value<Enum.FontWeight> = scope:Value(Enum.FontWeight.Regular)
	local weightCount: Fusion.Value<number> = scope:Value(1)
	scope:Observer(weightCount):onBind(function()
		weight:set(weights[peek(weightCount)])
	end)
	table.insert(scope, textEditButtonsFrame:FindFirstChild("TextWeight"):FindFirstChild("TextWeight").MouseButton1Click:Connect(function()
		if peek(weightCount) + 1 > #weights then
			weightCount:set(1)
		else
			weightCount:set(peek(weightCount) + 1)
		end
	end))
	
	local style: Fusion.Value<Enum.FontStyle> = scope:Value(Enum.FontStyle.Normal)
	local styleCount: Fusion.Value<number> = scope:Value(1)
	scope:Observer(styleCount):onBind(function()
		style:set(styles[peek(styleCount)])
	end)
	table.insert(scope, textEditButtonsFrame:FindFirstChild("Italic"):FindFirstChild("Italic").MouseButton1Click:Connect(function()
		if peek(styleCount) + 1 > #styles then
			styleCount:set(1)
		else
			styleCount:set(peek(styleCount) + 1)
		end
	end))
	
	local strokeThickness: Fusion.Value<number> = scope:Value(0)
	local strokeThicknessCount: Fusion.Value<number> = scope:Value(1)
	scope:Observer(strokeThicknessCount):onBind(function()
		strokeThickness:set(strokeThicknessRange[peek(strokeThicknessCount)])
	end)
	table.insert(scope, textEditButtonsFrame:FindFirstChild("Stroke"):FindFirstChild("Stroke").MouseButton1Click:Connect(function()
		if peek(strokeThicknessCount) + 1 > #strokeThicknessRange then
			strokeThicknessCount:set(1)
		else
			strokeThicknessCount:set(peek(strokeThicknessCount) + 1)
		end
	end))
	
	scope:Computed(function(use: Fusion.Use)
		fontFace:set(Font.new(use(selectedFontButton).FontFace.Family, use(weight), use(style)))
	end)
	
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
	
	return fontFace, strokeThickness
end

local function manageColors(mainFrame: Frame)
	local colorPickerShown: Fusion.Value<boolean> = scope:Value(false)
	
	local textAreaFrame: Frame = mainFrame.Middle.TextArea
	local colorsCanvas = textAreaFrame.Colors
	local colorsContainer: Frame = colorsCanvas.Container
	local colorPicker: ImageButton = textAreaFrame.ColorPicker
	
	local selectedColorButton: Fusion.Value<ImageButton> = scope:Value(colorsContainer:FindFirstChild("Default"))
	local selectedTextColor: Fusion.Value<Color3> = scope:Value(Color3.new())
	local selectedStrokeColor: Fusion.Value<Color3> = scope:Value(Color3.new())
	
	local textSelected: Fusion.Value<boolean> = scope:Value(true)
	local strokeSelected: Fusion.Value<boolean> = scope:Value(true)
	
	local function manageButton(button: TextButton, selected: Fusion.Value<boolean>)
		scope:Hydrate(button) {
			BackgroundColor3 = scope:Tween(scope:Computed(function(use: Fusion.Use)
				return use(selected) and Color3.fromRGB(215, 226, 244) or Color3.new(1, 1, 1)
			end), TweenInfo.new(0.1)),
			
			[OnEvent("MouseButton1Click")] = function()
				selected:set(not peek(selected))
			end,
		}
	end
	
	manageButton(colorsCanvas.TextColor, textSelected)
	manageButton(colorsCanvas.StrokeColor, strokeSelected)
	
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
			return use(selectedColorButton).BackgroundColor3
		end), TweenInfo.new(0.5)),
	}
	scope:Hydrate(colorsCanvas) {
		GroupTransparency = scope:Tween(scope:Computed(function(use: Fusion.Use)
			return use(colorPickerShown) and 0 or 1
		end), TweenInfo.new(0.2)),
		Size = scope:Spring(scope:Computed(function(use: Fusion.Use)
			return use(colorPickerShown) and UDim2.fromScale(0.463, 0.836) or UDim2.fromScale(0, 0.836)
		end), 25, 0.8),
	}
	
	for _, colorButton: ImageButton? in colorsContainer:GetChildren() do
		if not colorButton:IsA("TextButton") then
			continue
		end
		scope:Hydrate(colorButton) {
			[OnEvent("MouseButton1Down")] = function()
				selectedColorButton:set(colorButton)
				colorPickerShown:set(false)
				
				local color = peek(selectedColorButton).BackgroundColor3
				if peek(textSelected) then
					selectedTextColor:set(color)
				end
				if peek(strokeSelected) then
					selectedStrokeColor:set(color)
				end
			end
		}
	end
	
	return selectedTextColor, selectedStrokeColor
end

Booth.menuLoaded = function(menu: ScreenGui)
	scope:doCleanup()
	
	table.insert(scope, menu:GetPropertyChangedSignal("Enabled"):Connect(function()
		if not menu:GetAttribute("Enabled") then
			interactingController.Interacted:Fire("Booths", "CancelEdit")
		end
	end))
	
	local mainFrame: Frame = menu.Main
	scope:Hydrate(mainFrame.Side.UnclaimBooth) {
		[OnEvent("MouseButton1Click")] = function()
			interactingService:InteractAttempt("Booths", "Unclaim"):andThen(function(success: boolean?)
				if success then
					controller:CloseMenu(menu)
				end
			end)
		end,
	}
	
	
	local textColor, strokeColor = manageColors(mainFrame)
	local font, strokeThickness = manageFonts(mainFrame)
	
	
	local textBox: TextBox = mainFrame.Middle.TextArea:FindFirstChild("TextBox")
	local text: Fusion.Value<string> = scope:Value("")
	
	local function updateBoard()
		interactingService:InteractAttempt("Booths", "SetTextAttempt", peek(text),
			peek(textColor), peek(strokeColor),
			peek(font), peek(strokeThickness)
		)
	end
	scope:Observer(textColor):onChange(updateBoard)
	scope:Observer(strokeColor):onChange(updateBoard)
	scope:Observer(font):onChange(updateBoard)
	scope:Observer(strokeThickness):onChange(updateBoard)
	
	scope:Hydrate(textBox) {
		FontFace = font,
		TextColor3 = textColor,
		[OnChange("Text")] = function(newText)
			text:set(newText)
		end,
		[OnEvent("FocusLost")] = function(commit)
			if not commit then
				return
			end
			updateBoard()
		end,
	}
	scope:Hydrate(textBox:FindFirstChildWhichIsA("UIStroke")) {
		Color = strokeColor,
		Thickness = strokeThickness,
	}
end

return Booth