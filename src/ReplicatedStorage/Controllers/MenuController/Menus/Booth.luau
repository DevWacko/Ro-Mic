-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Fusion = require(Packages.Fusion)
local Trove = require(Packages.Trove)
local Knit = require(Packages.Knit)

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
local _trove = Trove.new()

local savedIndexes = {
	textColor = 1,
	strokeColor = 1,
	
	font = 1,
	weight = 1,
	style = 1,
	
	strokeOpacity = BoothsData.Defaults.DESCRIPTION_DATA.strokeOpacity
}
local currentIndexes: { [string]: Fusion.Value<number> } = {}

local mainFrame: Frame
local middleFrame: Frame
local textArea: Frame
local colorsFrame: Frame

local function getBoothTextData()
	playerDataService:GetValue("BoothTextData"):andThen(function(boothTextData)
		-- Saved --
		savedIndexes.textColor = boothTextData.TextColorIndex
		savedIndexes.strokeColor = boothTextData.StrokeColorIndex
		
		savedIndexes.font = boothTextData.FontIndex
		savedIndexes.weight = boothTextData.WeightIndex
		savedIndexes.style = boothTextData.StyleIndex
		
		savedIndexes.strokeOpacity = boothTextData.StrokeOpacity
		
		-- Current --
		currentIndexes.textColorIndex:set(savedIndexes.textColor)
		currentIndexes.strokeColorIndex:set(savedIndexes.strokeColor)
		
		currentIndexes.fontIndex:set(savedIndexes.font)
		currentIndexes.weightIndex:set(savedIndexes.weight)
		currentIndexes.styleIndex:set(savedIndexes.style)
		
		currentIndexes.strokeOpacity:set(savedIndexes.strokeOpacity)
	end):catch(function(err: string?)
		warn("Failed to load booth text data: " .. tostring(err))
	end)
end

Booth.init = function()
	interactingController = Knit.GetController("InteractingController")
	controller = Knit.GetController("MenuController")
	
	interactingService = Knit.GetService("InteractingService")
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
		--[[ GroupTransparency = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
			return use(shown) and 0 or 1
		end), TweenInfo.new(0.5)), ]]
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
	
	local fontContents: ScrollingFrame = mainFrame.FontsDropdown.FontsScrolling
	local lineWeightContents: ScrollingFrame = mainFrame.LineWeightDropdown.WeightDropDown
	
	local selectedWeightButton: Fusion.Value<TextButton> = tempScope:Value(lineWeightContents:FindFirstChild(tostring(peek(currentIndexes.weightIndex))))
	tempScope:Observer(currentIndexes.weightIndex):onBind(function()
		selectedWeightButton:set(lineWeightContents:FindFirstChild(tostring(peek(currentIndexes.weightIndex))))
	end)
	
	local selectedFontButton: Fusion.Value<TextButton> = tempScope:Value(fontContents:FindFirstChild(tostring(peek(currentIndexes.fontIndex))))
	tempScope:Observer(currentIndexes.fontIndex):onBind(function()
		selectedFontButton:set(fontContents:FindFirstChild(tostring(peek(currentIndexes.fontIndex))))
	end)
	
	local textEditButtonsFrame: Frame = mainFrame:FindFirstChild("Frame"):FindFirstChild("Frame")
	
	local fontDropdown: CanvasGroup = mainFrame:FindFirstChild("FontsDropdown")
	local fontStartSize = fontDropdown.Size
	--[[ manageDropdown(
		mainFrame:FindFirstChild("Type"):FindFirstChild("Fonts"),
		fontDropdown,
		shownValues["Fonts"],
		fontStartSize, UDim2.fromScale(fontStartSize.X.Scale, 0)
	) ]]
	
	local textWeightDropdown: CanvasGroup = mainFrame:FindFirstChild("LineWeightDropdown")
	local weightStartSize = textWeightDropdown.Size
	--[[ manageDropdown(
		textEditButtonsFrame:FindFirstChild("TextWeight"):FindFirstChild("TextWeight"),
		textWeightDropdown,
		shownValues["Weight"],
		weightStartSize, UDim2.fromScale(weightStartSize.X.Scale, 0)
	) ]]
	
	local strokeDropdown: CanvasGroup = mainFrame:FindFirstChild("StrokeDropdown")
	local strokeStartSize = strokeDropdown.Size
	--[[ manageDropdown(
		textEditButtonsFrame:FindFirstChild("Stroke"):FindFirstChild("Stroke"),
		mainFrame:FindFirstChild("StrokeDropdown"),
		shownValues["Stroke"],
		strokeStartSize, UDim2.fromScale(0, strokeStartSize.Y.Scale)
	) ]]
	local strokeBar: Frame = strokeDropdown:FindFirstChild("Stroke")
	local strokeSlider: Frame = strokeBar:FindFirstChild("Frame")
	strokeSlider:SetAttribute("Value", peek(currentIndexes.strokeOpacity))
	local function setOpacity()
		local steppedValue = math.floor(strokeSlider:GetAttribute("Value") * 100) / 100
		strokeBar:FindFirstChild("Value").Text = steppedValue
		currentIndexes.strokeOpacity:set(steppedValue)
	end
	table.insert(tempScope, strokeSlider:GetAttributeChangedSignal("Value"):Connect(setOpacity))
	setOpacity()
	
--[[ 	tempScope:Hydrate(mainFrame.Type.Fonts.Arrow.Icon) {
		Rotation = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
			return use(shownValues["Fonts"]) and 0 or -90
		end), 25, 0.8)
	} ]]
	tempScope:Hydrate(mainFrame:FindFirstChild("Type"):FindFirstChild("Fonts"):FindFirstChild("SelectedFont")) {
		Text = tempScope:Computed(function(use: Fusion.Use)
			return use(selectedFontButton).Text
		end),
		FontFace = tempScope:Computed(function(use: Fusion.Use)
			return use(selectedFontButton).FontFace
		end),
	}
	
	table.insert(tempScope, textEditButtonsFrame:FindFirstChild("Italic"):FindFirstChild("Italic").MouseButton1Click:Connect(function()
		if peek(currentIndexes.styleIndex) + 1 > #BoothsData.BoothStyling.STYLES then
			currentIndexes.styleIndex:set(1)
		else
			currentIndexes.styleIndex:set(peek(currentIndexes.styleIndex) + 1)
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
				currentIndexes.fontIndex:set(tonumber(fontButton.Name))
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
				currentIndexes.weightIndex:set(tonumber(weightButton.Name))
			end
		}
	end
end

local function manageColors()
	local colorPickerShown: Fusion.Value<boolean> = tempScope:Value(true)
	
	colorsFrame = textArea:FindFirstChild("Frame"):FindFirstChild("Colors")
	local colorsContainer: Frame = colorsFrame.Container
	local colorPicker: ImageButton = textArea:FindFirstChild("Frame").ColorPicker
	
	local selectedColorButton: Fusion.Value<ImageButton> = tempScope:Value(colorsContainer:FindFirstChild(tostring(peek(currentIndexes.textColorIndex))))
	
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
	
	manageButton(colorsFrame.TextColor, textSelected)
	manageButton(colorsFrame.StrokeColor, strokeSelected)
	
	--[[ tempScope:Hydrate(colorPicker) {
		Visible = tempScope:Computed(function(use: Fusion.Use)
			return use(colorPickerShown)
		end),
		[OnEvent("MouseButton1Down")] = function()
			colorPickerShown:set(false)
		end,
	} ]]
	tempScope:Hydrate(colorPicker:FindFirstChild("ImageLabel")) {
		ImageColor3 = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
			return BoothsData.BoothStyling.COLORS[use(currentIndexes.textColorIndex)]
		end), TweenInfo.new(0.5)),
	}
	-- tempScope:Hydrate(colorsFrame) {
	-- 	--  = tempScope:Tween(tempScope:Computed(function(use: Fusion.Use)
	-- 	-- 	return use(colorPickerShown) and 0 or 1
	-- 	-- end), TweenInfo.new(0.2)),
	-- 	Size = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
	-- 		return use(colorPickerShown) and UDim2.fromScale(0.463, 0.836) or UDim2.fromScale(0, 0.836)
	-- 	end), 25, 0.8),
	-- }
	
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
					currentIndexes.textColorIndex:set(index)
				end
				if peek(strokeSelected) then
					currentIndexes.strokeColorIndex:set(index)
				end
			end
		}
	end
end

Booth.menuLoaded = function(menu: ScreenGui)
	playerDataService = Knit.GetService("PlayerDataService")
	
	tempScope:doCleanup()
	_trove:Clean()
	
	currentIndexes = {
		textColorIndex = tempScope:Value(savedIndexes.textColor),
		strokeColorIndex = tempScope:Value(savedIndexes.strokeColor),
		
		fontIndex = tempScope:Value(savedIndexes.font),
		weightIndex = tempScope:Value(savedIndexes.weight),
		styleIndex = tempScope:Value(savedIndexes.style),
		
		strokeOpacity = tempScope:Value(savedIndexes.strokeOpacity)
	}
	
	playerDataService.ProfileLoaded:Connect(getBoothTextData)
	print("GET")
	if Players.LocalPlayer:GetAttribute("ProfileLoaded") then
		getBoothTextData()
	end
	
	mainFrame = menu:WaitForChild("Booth")
	textArea = mainFrame:FindFirstChild("Type")
	colorsFrame = textArea:FindFirstChild("Frame"):FindFirstChild("Colors")
	
	for _, colorButton: TextButton? in colorsFrame.Container:GetChildren() do
		if not colorButton:IsA("TextButton") then
			continue
		end
		local color = colorButton.BackgroundColor3
		BoothsData.BoothStyling.COLORS[tonumber(colorButton.Name)] = color
	end
	for _, fontButton: TextButton? in mainFrame.FontsDropdown.FontsScrolling:GetChildren() do
		if not fontButton:IsA("TextButton") then
			continue
		end
		local font = fontButton.FontFace
		BoothsData.BoothStyling.FONTS[tonumber(fontButton.Name)] = font
	end
	
	_trove:Add(controller:ObserveMenuClosing("TextBooth", function()
		interactingController.Interacted:Fire("Booths", "CancelEdit")
	end))
	
	tempScope:Hydrate(mainFrame:FindFirstChild("Frame").UnclaimBooth) {
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
	
	local textBox: TextBox = textArea:FindFirstChild("Frame"):FindFirstChild("TextBox")
	local text: Fusion.Value<string> = tempScope:Value("")
	
	local function updateBoard()
		interactingService:InteractAttempt("Booths", "SetTextAttempt",
			peek(text),
			peek(currentIndexes.textColorIndex), peek(currentIndexes.strokeColorIndex),
			peek(currentIndexes.fontIndex), peek(currentIndexes.weightIndex), peek(currentIndexes.styleIndex),
			peek(currentIndexes.strokeOpacity)
		)
	end
	tempScope:Observer(currentIndexes.textColorIndex):onChange(updateBoard)
	tempScope:Observer(currentIndexes.strokeColorIndex):onChange(updateBoard)
	
	tempScope:Observer(currentIndexes.fontIndex):onChange(updateBoard)
	tempScope:Observer(currentIndexes.weightIndex):onChange(updateBoard)
	tempScope:Observer(currentIndexes.styleIndex):onChange(updateBoard)
	
	tempScope:Observer(currentIndexes.strokeOpacity):onChange(updateBoard)
	
	tempScope:Hydrate(textBox) {
		FontFace = tempScope:Computed(function(use: Fusion.Use)
			return Font.new(BoothsData.BoothStyling.FONTS[use(currentIndexes.fontIndex)].Family, BoothsData.BoothStyling.WEIGHTS[use(currentIndexes.weightIndex)], BoothsData.BoothStyling.STYLES[use(currentIndexes.styleIndex)])
		end),
		TextColor3 = tempScope:Computed(function(use: Fusion.Use)
			return BoothsData.BoothStyling.COLORS[use(currentIndexes.textColorIndex)]
		end),
		PlaceholderColor3 = tempScope:Computed(function(use: Fusion.Use)
			return BoothsData.BoothStyling.COLORS[use(currentIndexes.textColorIndex)]
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
			return BoothsData.BoothStyling.COLORS[use(currentIndexes.strokeColorIndex)]
		end),
		Transparency = tempScope:Computed(function(use: Fusion.Use)
			return 1 - use(currentIndexes.strokeOpacity)
		end),
	}
end

return Booth