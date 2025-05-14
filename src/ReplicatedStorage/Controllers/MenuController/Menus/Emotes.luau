-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local EmotesFolder = ReplicatedStorage.Assets.Animations.Emotes
local Packages = ReplicatedStorage.Packages

-- Modules --
local Data = require(ReplicatedStorage.Source.Data.Gui.Emotes)

local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

local peek = Fusion.peek

local getAnimationFromPath = require(ReplicatedStorage.Source.Utils.Character.getAnimationFromPath)

-- Main Module --
local Emotes = { MenuName = "Emotes" }

-- Local --
local scope = Fusion:scoped()
local framesShown: { [GuiObject]: Fusion.Value<boolean> } = {}

local categoryAnimations: { [Folder]: { Animation } } = {}
local tracks: { [string]: { [string]: AnimationTrack } } = {}
local currentTrack: AnimationTrack?
local currentSpeed: number?

local mainFrame: Frame
local mainMenu: ScrollingFrame
local robloxDancesFrame: ScrollingFrame

local player = Players.LocalPlayer
local char: Model?
local hum: Humanoid?
local animator: Animator?

Emotes.init = function()
	
end

--[[ Emotes.shown = function(menu: ScreenGui, ...)
	
end ]]

local function setFrame(frameName: string)
	for otherMenuName, shown in pairs(framesShown) do
		if otherMenuName.Name == frameName then
			shown:set(true)
		else
			shown:set(false)
		end
	end
end

Emotes.closed = function(menu: ScreenGui, ...)
	setFrame(Data.Defaults.START_MENU_NAME)
end

local function manageMainMenu()
	for _, button: GuiButton in mainMenu:GetChildren() do
		if not button:IsA("GuiButton") then
			continue
		end
		table.insert(scope, button.MouseButton1Click:Connect(function()
			setFrame(button.Name)
		end))
	end
end

local function manageAnimations()
	for _, categoryFolder: Folder in EmotesFolder:GetChildren() do
		local containerFrame: GuiObject = mainMenu:FindFirstChild(categoryFolder.Name)
		if containerFrame == nil then
			continue
		end
		local category = {}
		for _, animation: Animation in categoryFolder:GetChildren() do
			table.insert(category, animation)
		end
		categoryAnimations[categoryFolder] = category
	end
	
	local function charAdded(addedChar: Model)
		hum = addedChar:WaitForChild("Humanoid")
		if hum then
			animator = hum:FindFirstChildWhichIsA("Animator")
			for categoryFold, anims in categoryAnimations do
				local categoryTracks = {}
				for _, anim in anims do
					categoryTracks[anim.Name] = animator:LoadAnimation(anim)
				end
				tracks[categoryFold.Name] = categoryTracks
			end
		end
		
		for categoryName, categoryTracks in tracks do
			local categoryContainer: GuiObject? = mainFrame:FindFirstChild(categoryName)
			if categoryContainer == nil then
				continue
			end
			for trackName, track in categoryTracks do
				local button: GuiButton? = categoryContainer:FindFirstChild(trackName)
				if button == nil then
					continue
				end
				table.insert(scope, button.MouseButton1Click:Connect(function()
					if animator == nil or track == nil then return end
					if not track.IsPlaying then
						for _, oldTracks in tracks do
							for _, oldTrack in oldTracks do
								oldTrack:Stop()
							end
						end
						track:Play()
						currentTrack = track
						currentTrack:AdjustSpeed(currentSpeed)
					elseif track.IsPlaying then
						track:Stop()
						currentTrack = nil
					end
				end))
			end
		end
	end
	table.insert(scope, player.CharacterAdded:Connect(charAdded))
	if player.Character then
		charAdded(player.Character)
	end
end

Emotes.menuLoaded = function(menu: ScreenGui)
	scope:doCleanup()
	
	mainFrame = menu:FindFirstChild("Main")
	mainMenu = mainFrame:FindFirstChild("MainMenu")
	robloxDancesFrame = mainFrame:FindFirstChild("RobloxDances")
	
	for _, frame: Frame | ScrollingFrame in mainFrame:GetChildren() do
		if not frame:IsA("ScrollingFrame") then
			continue
		end
		local shown = scope:Value(frame.Name == Data.Defaults.START_MENU_NAME)
		scope:Observer(shown):onBind(function()
			frame.Visible = peek(shown)
		end)
		framesShown[frame] = shown
	end
	
	table.insert(scope, mainMenu:GetPropertyChangedSignal("Visible"):Connect(function()
		mainFrame:FindFirstChild("DanceSpeed").Visible = mainMenu.Visible
	end))
	
	local bar = mainFrame:FindFirstChild("DanceSpeed"):FindFirstChild("Bar")
	table.insert(scope, bar:GetAttributeChangedSignal("Value"):Connect(function()
		--currentTrack.Speed = 
		local speed = bar:GetAttribute("Value")
		currentTrack:AdjustSpeed(speed)
		currentSpeed = speed
	end))
	
	manageMainMenu()
	manageAnimations()
end

return Emotes