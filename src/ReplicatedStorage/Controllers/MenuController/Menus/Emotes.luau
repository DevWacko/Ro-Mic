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
local tracks: { AnimationTrack } = {}

local mainFrame: Frame
local mainMenu: ScrollingFrame
local robloxDancesFrame: ScrollingFrame

local player = Players.LocalPlayer
local char: Model?
local hum: Humanoid?
local animator: Animator?

Emotes.init = function()
	for _, categoryFolder: Folder in EmotesFolder:GetChildren() do
		local containerFrame: GuiObject in mainMenu:FindFirstChild(categoryFolder.Name)
		if containerFrame == nil then
			continue
		end
		local category = {}
		for _, animation: Animation in categoryFolder:GetChildren() do
			local animButton: GuiButton? = containerFrame:FindFirstChild(animation.Name)
			if not animButton then
				continue
			end
			table.insert(category, animation)
		end
		categoryAnimations[categoryFolder] = category
	end
	
	local function charAdded(addedChar: Model)
		hum = addedChar:WaitForChild("Humanoid")
		if hum then
			animator = hum:FindFirstChildWhichIsA("Animator")
			for _, anims in categoryAnimations do
				for _, anim in anims do
					table.insert(tracks, animator:LoadAnimation(anim))
				end
			end
		end
	end
	table.insert(scope, player.CharacterAdded:Connect(charAdded))
	if player.Character then
		charAdded(player.Character)
	end
end

Emotes.shown = function(menu: ScreenGui, ...)
	for categoryFold, _ in categoryAnimations do
		
	end
end

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

--[[ local function manageRobloxDancesFrame()
	for _, danceButton: GuiButton in robloxDancesFrame:GetChildren() do
		if not danceButton:IsA("GuiButton") then
			continue
		end
		table.insert(scope, danceButton.MouseButton1Click:Connect(function()
			if not animator then
				return
			end
			
			local trackPath = Data.RobloxDances[tonumber(danceButton.Name)]
			local tracks = animator:GetPlayingAnimationTracks()
			
			if #tracks == 0 then
				animationService:PlayAnimationAttempt(trackPath, true)
				return
			end
			
			animationService:TrackIsPlaying(trackPath):andThen(function(isPlaying: boolean?)
				if not isPlaying then
					animationService:PlayAnimationAttempt(trackPath, true)
				else
					animationService:StopAnimationAttempt(trackPath)
				end
			end)
		end))
	end
end ]]


local function manageAnimations()
	
end

Emotes.menuLoaded = function(menu: ScreenGui)
	scope:doCleanup()
	
	mainFrame = menu:FindFirstChild("Main")
	mainMenu = mainFrame:FindFirstChild("MainMenu")
	robloxDancesFrame = mainFrame:FindFirstChild("RobloxDances")
	
	for _, frame: Frame | ScrollingFrame in mainFrame:GetChildren() do
		if not frame:IsA("Frame") and not frame:IsA("ScrollingFrame") then
			continue
		end
		local shown = scope:Value(frame.Name == Data.Defaults.START_MENU_NAME)
		scope:Observer(shown):onBind(function()
			frame.Visible = peek(shown)
		end)
		framesShown[frame] = shown
	end
	manageMainMenu()
	manageAnimations()
	--manageRobloxDancesFrame()
end

return Emotes