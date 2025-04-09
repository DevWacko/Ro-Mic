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
local controller

local interactingService
local playerDataService

local mainScope: Fusion.Scope = Fusion:scoped()
local tempScope: Fusion.Scope = Fusion:scoped()

local textColorIndex: Fusion.Value<number> = mainScope:Value(1)
local strokeColorIndex: Fusion.Value<number> = mainScope:Value(1)

local weightIndex: Fusion.Value<number> = mainScope:Value(1)
local styleIndex: Fusion.Value<number> = mainScope:Value(1)
local fontIndex: Fusion.Value<number> = mainScope:Value(1)

local strokeIndex: Fusion.Value<number> = mainScope:Value(1)

local colors: { [number]: Color3 } = {}
local fonts: { [number]: Font } = {}
local weights = {
	[1] = Enum.FontWeight.Regular,
	[2] = Enum.FontWeight.SemiBold,
	[3] = Enum.FontWeight.Bold,
	[4] = Enum.FontWeight.Heavy,
	[5] = Enum.FontWeight.ExtraLight,
	[6] = Enum.FontWeight.Light,
}
local styles = {
	[1] = Enum.FontStyle.Normal,
	[2] = Enum.FontStyle.Italic,
}
local strokeThicknessRange = {
	[1] = 0,
	[2] = 3,
}

local mainFrame: Frame
local middleFrame: Frame
local textArea: Frame
local colorsCanvas: CanvasGroup

Booth.init = function()
	interactingController = Knit.GetController("InteractingController")
	controller = Knit.GetController("MenuController")
	
	interactingService = Knit.GetService("InteractingService")
	playerDataService = Knit.GetService("PlayerDataService")
	
	playerDataService.ProfileLoaded:Connect(function()
		playerDataService:GetValue("BoothTextData"):andThen(function(boothTextData)
			print(boothTextData)
			textColorIndex:set(boothTextData.TextColorIndex)
			strokeColorIndex:set(boothTextData.StrokeColorIndex)
			
			fontIndex:set(boothTextData.FontIndex)
			--styleIndex:set(boothTextData.StyleIndex)
			--weightIndex:set(boothTextData.WeightIndex)
			
			strokeIndex:set(boothTextData.StrokeThicknessIndex)
		end):catch(function(err: string?)
			warn("Failed to load booth text data: " .. tostring(err))
		end)
	end)
end

local function manageFonts()
	local fontsDropdownShown: Fusion.Value<boolean> = tempScope:Value(false)
	local textWeightDropdownShown: Fusion.Value<boolean> = tempScope:Value(false)
	
	local fontContents: ScrollingFrame = mainFrame.FontsDropdown.Contents
	local lineWeightContents: ScrollingFrame = mainFrame.LineWeightDropdown.Contents
	
	local selectedWeightButton: Fusion.Value<TextButton> = tempScope:Value(lineWeightContents:FindFirstChild(tostring(peek(weightIndex))))
	tempScope:Observer(weightIndex):onBind(function()
		selectedWeightButton:set(lineWeightContents:FindFirstChild(tostring(peek(weightIndex))))
	end)
	
	local selectedFontButton: Fusion.Value<TextButton> = tempScope:Value(fontContents:FindFirstChild(tostring(peek(fontIndex))))
	tempScope:Observer(fontIndex):onBind(function()
		selectedFontButton:set(fontContents:FindFirstChild(tostring(peek(fontIndex))))
	end)
	
	local textEditButtonsFrame: Frame = mainFrame.Side.TextEditButtons
	
	table.insert(tempScope, mainFrame.Middle.Fonts.MouseButton1Click:Connect(function()
		fontsDropdownShown:set(not peek(fontsDropdownShown))
	end))
	tempScope:Hydrate(mainFrame.FontsDropdown) {
		GroupTransparency = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
			return use(fontsDropdownShown) and 0 or 1
		end), TweenInfo.new(0.5)),
		Size = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
			return use(fontsDropdownShown) and UDim2.fromScale(0.245, 0.526) or UDim2.fromScale(0.245, 0)
		end), 25, 0.8),
	}
	
	table.insert(tempScope, textEditButtonsFrame:FindFirstChild("TextWeight"):FindFirstChild("TextWeight").MouseButton1Click:Connect(function()
		textWeightDropdownShown:set(not peek(textWeightDropdownShown))
	end))
	tempScope:Hydrate(mainFrame.LineWeightDropdown) {
		GroupTransparency = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
			return use(textWeightDropdownShown) and 0 or 1
		end), TweenInfo.new(0.5)),
		Size = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
			return use(textWeightDropdownShown) and UDim2.fromScale(0.245, 0.474) or UDim2.fromScale(0.245, 0)
		end), 25, 0.8),
	}
	
	tempScope:Hydrate(mainFrame.Middle.Fonts.Arrow.Icon) {
		Rotation = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
			return use(fontsDropdownShown) and 0 or -90
		end), 25, 0.8)
	}
	tempScope:Hydrate(mainFrame:FindFirstChild("Middle"):FindFirstChild("Fonts"):FindFirstChild("SelectedFont")) {
		Text = tempScope:Computed(function(use: Fusion.Use)
			return use(selectedFontButton).Text
		end),
		FontFace = tempScope:Computed(function(use: Fusion.Use)
			return use(selectedFontButton).FontFace
		end),
	}
	
	table.insert(tempScope, textEditButtonsFrame:FindFirstChild("Italic"):FindFirstChild("Italic").MouseButton1Click:Connect(function()
		if peek(styleIndex) + 1 > #styles then
			styleIndex:set(1)
		else
			styleIndex:set(peek(styleIndex) + 1)
		end
	end))
	
	table.insert(tempScope, textEditButtonsFrame:FindFirstChild("Stroke"):FindFirstChild("Stroke").MouseButton1Click:Connect(function()
		if peek(strokeIndex) + 1 > #strokeThicknessRange then
			strokeIndex:set(1)
		else
			strokeIndex:set(peek(strokeIndex) + 1)
		end
	end))
	
	for _, fontButton: TextButton? in fontContents:GetChildren() do
		if not fontButton:IsA("TextButton") then
			continue
		end
		tempScope:Hydrate(fontButton) {
			BackgroundColor3 = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
				return use(selectedFontButton) == fontButton and Color3.fromRGB(215, 224, 244) or Color3.new(1, 1, 1)
			end), TweenInfo.new(0.25)),
			[OnEvent("MouseButton1Down")] = function()
				selectedFontButton:set(fontButton)
				fontIndex:set(tonumber(fontButton.Name))
			end
		}
	end
	for _, weightButton: TextButton? in lineWeightContents:GetChildren() do
		if not weightButton:IsA("TextButton") then
			continue
		end
		tempScope:Hydrate(weightButton) {
			BackgroundColor3 = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
				return use(selectedWeightButton) == weightButton and Color3.fromRGB(215, 224, 244) or Color3.new(1, 1, 1)
			end), TweenInfo.new(0.25)),
			[OnEvent("MouseButton1Down")] = function()
				weightIndex:set(tonumber(weightButton.Name))
			end
		}
	end
end

local function manageColors()
	local colorPickerShown: Fusion.Value<boolean> = tempScope:Value(false)
	
	local textAreaFrame: Frame = mainFrame.Middle.TextArea
	local colorsCanvas = textAreaFrame.Colors
	local colorsContainer: Frame = colorsCanvas.Container
	local colorPicker: ImageButton = textAreaFrame.ColorPicker
	
	local selectedColorButton: Fusion.Value<ImageButton> = tempScope:Value(colorsContainer:FindFirstChild(tostring(peek(textColorIndex))))
	
	local textSelected: Fusion.Value<boolean> = tempScope:Value(true)
	local strokeSelected: Fusion.Value<boolean> = tempScope:Value(true)
	
	local function manageButton(button: TextButton, selected: Fusion.Value<boolean>)
		tempScope:Hydrate(button) {
			BackgroundColor3 = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
				return use(selected) and Color3.fromRGB(215, 226, 244) or Color3.new(1, 1, 1)
			end), TweenInfo.new(0.1)),
			
			[OnEvent("MouseButton1Click")] = function()
				selected:set(not peek(selected))
			end,
		}
	end
	
	manageButton(colorsCanvas.TextColor, textSelected)
	manageButton(colorsCanvas.StrokeColor, strokeSelected)
	
	tempScope:Hydrate(colorPicker) {
		Visible = tempScope:Computed(function(use: Fusion.Use)
			return not use(colorPickerShown)
		end),
		[OnEvent("MouseButton1Down")] = function()
			colorPickerShown:set(true)
		end,
	}
	tempScope:Hydrate(colorPicker.Bucket) {
		ImageColor3 = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
			return colors[use(textColorIndex)]
		end), TweenInfo.new(0.5)),
	}
	tempScope:Hydrate(colorsCanvas) {
		GroupTransparency = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
			return use(colorPickerShown) and 0 or 1
		end), TweenInfo.new(0.2)),
		Size = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
			return use(colorPickerShown) and UDim2.fromScale(0.463, 0.836) or UDim2.fromScale(0, 0.836)
		end), 25, 0.8),
	}
	
	for _, colorButton: ImageButton? in colorsContainer:GetChildren() do
		if not colorButton:IsA("TextButton") then
			continue
		end
		tempScope:Hydrate(colorButton) {
			[OnEvent("MouseButton1Down")] = function()
				selectedColorButton:set(colorButton)
				colorPickerShown:set(false)
				
				local index = tonumber(colorButton.Name)
				if peek(textSelected) then
					textColorIndex:set(index)
				end
				if peek(strokeSelected) then
					strokeColorIndex:set(index)
				end
			end
		}
	end
end

Booth.menuLoaded = function(menu: ScreenGui)
	tempScope:doCleanup()
	
	mainFrame = menu:WaitForChild("Main")
	middleFrame = mainFrame:FindFirstChild("Middle")
	textArea = middleFrame:FindFirstChild("TextArea")
	colorsCanvas = textArea:FindFirstChild("Colors")
	
	for _, colorButton: TextButton? in colorsCanvas.Container:GetChildren() do
		if not colorButton:IsA("TextButton") then
			continue
		end
		local color = colorButton.BackgroundColor3
		colors[tonumber(colorButton.Name)] = color
	end
	for _, fontButton: TextButton? in mainFrame.FontsDropdown.Contents:GetChildren() do
		if not fontButton:IsA("TextButton") then
			continue
		end
		local font = fontButton.FontFace
		fonts[tonumber(fontButton.Name)] = font
	end
	
	table.insert(tempScope, menu:GetPropertyChangedSignal("Enabled"):Connect(function()
		if not menu:GetAttribute("Enabled") then
			interactingController.Interacted:Fire("Booths", "CancelEdit")
		end
	end))
	
	tempScope:Hydrate(mainFrame.Side.UnclaimBooth) {
		[OnEvent("MouseButton1Click")] = function()
			interactingService:InteractAttempt("Booths", "Unclaim"):andThen(function(success: boolean?)
				if success then
					controller:CloseMenu(menu)
				end
			end)
		end,
	}
	
	manageColors()
	manageFonts()
	
	local textBox: TextBox = mainFrame.Middle.TextArea:FindFirstChild("TextBox")
	local text: Fusion.Value<string> = tempScope:Value("")
	
	local function updateBoard()
		interactingService:InteractAttempt("Booths", "SetTextAttempt", peek(text),
			colors[peek(textColorIndex)], colors[peek(strokeColorIndex)],
			fonts[peek(fontIndex)], strokeThicknessRange[peek(strokeIndex)],
			peek(textColorIndex), peek(strokeColorIndex),
			peek(fontIndex), peek(strokeIndex)
		)
	end
	tempScope:Observer(textColorIndex):onChange(updateBoard)
	tempScope:Observer(strokeColorIndex):onChange(updateBoard)
	tempScope:Observer(fontIndex):onChange(updateBoard)
	tempScope:Observer(strokeIndex):onChange(updateBoard)
	
	tempScope:Hydrate(textBox) {
		FontFace = tempScope:Computed(function(use: Fusion.Use)
			return Font.new(fonts[use(fontIndex)].Family, weights[use(weightIndex)], styles[use(styleIndex)])
		end),
		TextColor3 = tempScope:Computed(function(use: Fusion.Use)
			return colors[use(textColorIndex)]
		end),
		PlaceholderColor3 = tempScope:Computed(function(use: Fusion.Use)
			return colors[use(textColorIndex)]
		end),
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
	tempScope:Hydrate(textBox:FindFirstChildWhichIsA("UIStroke")) {
		Color = tempScope:Computed(function(use: Fusion.Use)
			return colors[use(strokeColorIndex)]
		end),
		Thickness = tempScope:Computed(function(use: Fusion.Use)
			return strokeThicknessRange[use(strokeIndex)]
		end),
	}
end

return Booth