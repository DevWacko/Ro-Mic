-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local OnEvent, OnChange = Fusion.OnEvent, Fusion.OnChange
local peek = Fusion.peek

local BoothsData = require(ReplicatedStorage.Source.Data.Interacting.Booths)

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

local strokeOpacity: Fusion.Value<number> = mainScope:Value(BoothsData.Defaults.DESCRIPTION_DATA.strokeOpacity)

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
			textColorIndex:set(boothTextData.TextColorIndex)
			strokeColorIndex:set(boothTextData.StrokeColorIndex)
			
			fontIndex:set(boothTextData.FontIndex)
			weightIndex:set(boothTextData.WeightIndex)
			styleIndex:set(boothTextData.StyleIndex)
			
			strokeOpacity:set(boothTextData.StrokeOpacity)
		end):catch(function(err: string?)
			warn("Failed to load booth text data: " .. tostring(err))
		end)
	end)
end

local function manageDropdown(
	toggleButton: GuiButton,
	dropdown: CanvasGroup,
	shown: Fusion.Value<boolean>,
	showSize: UDim2, hideSize: UDim2
)
	table.insert(tempScope, toggleButton.MouseButton1Click:Connect(function()
		shown:set(not peek(shown))
	end))
	tempScope:Hydrate(dropdown) {
		GroupTransparency = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
			return use(shown) and 0 or 1
		end), TweenInfo.new(0.5)),
		Size = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
			return use(shown) and showSize or hideSize
		end), 25, 0.8),
	}
end

local function manageFonts()
	local shownValues: { [string]: Fusion.Value<boolean> } = {
		["Fonts"] = tempScope:Value(false),
		["Weight"] = tempScope:Value(false),
		["Stroke"] = tempScope:Value(false),
	}
	
	-- tempScope:Computed(function(use: Fusion.Use)
	-- 	shownValues["Fonts"]:set(use)
	-- end)
	
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
	
	local fontDropdown: CanvasGroup = mainFrame:FindFirstChild("FontsDropdown")
	local fontStartSize = fontDropdown.Size
	manageDropdown(
		mainFrame:FindFirstChild("Middle"):FindFirstChild("Fonts"),
		fontDropdown,
		shownValues["Fonts"],
		fontStartSize, UDim2.fromScale(fontStartSize.X.Scale, 0)
	)
	
	local textWeightDropdown: CanvasGroup = mainFrame:FindFirstChild("LineWeightDropdown")
	local weightStartSize = textWeightDropdown.Size
	manageDropdown(
		textEditButtonsFrame:FindFirstChild("TextWeight"):FindFirstChild("TextWeight"),
		textWeightDropdown,
		shownValues["Weight"],
		weightStartSize, UDim2.fromScale(weightStartSize.X.Scale, 0)
	)
	
	local strokeDropdown: CanvasGroup = mainFrame:FindFirstChild("StrokeDropdown")
	local strokeStartSize = strokeDropdown.Size
	manageDropdown(
		textEditButtonsFrame:FindFirstChild("Stroke"):FindFirstChild("Stroke"),
		mainFrame:FindFirstChild("StrokeDropdown"),
		shownValues["Stroke"],
		strokeStartSize, UDim2.fromScale(0, strokeStartSize.Y.Scale)
	)
	local strokeBar: Frame = strokeDropdown:FindFirstChild("Stroke")
	local strokeSlider: Frame = strokeBar:FindFirstChild("Slider")
	strokeSlider:SetAttribute("Value", peek(strokeOpacity))
	local function setOpacity()
		local steppedValue = math.floor(strokeSlider:GetAttribute("Value") * 100) / 100
		strokeBar:FindFirstChild("Value").Text = steppedValue
		strokeOpacity:set(steppedValue)
	end
	table.insert(tempScope, strokeSlider:GetAttributeChangedSignal("Value"):Connect(setOpacity))
	setOpacity()
	
	tempScope:Hydrate(mainFrame.Middle.Fonts.Arrow.Icon) {
		Rotation = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
			return use(shownValues["Fonts"]) and 0 or -90
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
		if peek(styleIndex) + 1 > #BoothsData.BoothStyling.STYLES then
			styleIndex:set(1)
		else
			styleIndex:set(peek(styleIndex) + 1)
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
			return BoothsData.BoothStyling.COLORS[use(textColorIndex)]
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
		BoothsData.BoothStyling.COLORS[tonumber(colorButton.Name)] = color
	end
	for _, fontButton: TextButton? in mainFrame.FontsDropdown.Contents:GetChildren() do
		if not fontButton:IsA("TextButton") then
			continue
		end
		local font = fontButton.FontFace
		BoothsData.BoothStyling.FONTS[tonumber(fontButton.Name)] = font
	end
	
	print("OBSERVING")
	table.insert(tempScope, controller:ObserveMenuClosing("TextBooth", function()
		print("CLOSED")
		interactingController.Interacted:Fire("Booths", "CancelEdit")
	end))
	
	tempScope:Hydrate(mainFrame.Side.UnclaimBooth) {
		[OnEvent("MouseButton1Click")] = function()
			interactingService:InteractAttempt("Booths", "Unclaim"):andThen(function(success: boolean?)
				if success then
					controller:CloseMenu("TextBooth")
				end
			end)
		end,
	}
	
	manageColors()
	manageFonts()
	
	local textBox: TextBox = mainFrame.Middle.TextArea:FindFirstChild("TextBox")
	local text: Fusion.Value<string> = tempScope:Value("")
	
	local function updateBoard()
		interactingService:InteractAttempt("Booths", "SetTextAttempt",
			peek(text),
			peek(textColorIndex), peek(strokeColorIndex),
			peek(fontIndex), peek(weightIndex), peek(styleIndex),
			peek(strokeOpacity)
		)
	end
	tempScope:Observer(textColorIndex):onChange(updateBoard)
	tempScope:Observer(strokeColorIndex):onChange(updateBoard)
	
	tempScope:Observer(fontIndex):onChange(updateBoard)
	tempScope:Observer(weightIndex):onChange(updateBoard)
	tempScope:Observer(styleIndex):onChange(updateBoard)
	
	tempScope:Observer(strokeOpacity):onChange(updateBoard)
	
	tempScope:Hydrate(textBox) {
		FontFace = tempScope:Computed(function(use: Fusion.Use)
			return Font.new(BoothsData.BoothStyling.FONTS[use(fontIndex)].Family, BoothsData.BoothStyling.WEIGHTS[use(weightIndex)], BoothsData.BoothStyling.STYLES[use(styleIndex)])
		end),
		TextColor3 = tempScope:Computed(function(use: Fusion.Use)
			return BoothsData.BoothStyling.COLORS[use(textColorIndex)]
		end),
		PlaceholderColor3 = tempScope:Computed(function(use: Fusion.Use)
			return BoothsData.BoothStyling.COLORS[use(textColorIndex)]
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
			return BoothsData.BoothStyling.COLORS[use(strokeColorIndex)]
		end),
		Transparency = tempScope:Computed(function(use: Fusion.Use)
			return 1 - use(strokeOpacity)
		end),
	}
end

return Booth