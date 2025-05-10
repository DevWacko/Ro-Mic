-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
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

local mainFrame: Frame
local mainMenu: ScrollingFrame
local robloxDancesFrame: ScrollingFrame

local animationService

local player = Players.LocalPlayer
local char: Model?
local hum: Humanoid?
local animator: Animator?

Emotes.init = function()
	animationService = Knit.GetService("AnimationService")
end

Emotes.shown = function(menu: ScreenGui, ...)
	
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

local function manageNewChar(newChar: Model)
	char = newChar
	hum = char:WaitForChild("Humanoid")
	animator = hum:WaitForChild("Animator")
end

Emotes.menuLoaded = function(menu: ScreenGui)
	scope:doCleanup()
	
	mainFrame = menu:FindFirstChild("Main")
	mainMenu = mainFrame:FindFirstChild("MainMenu")
	robloxDancesFrame = mainFrame:FindFirstChild("RobloxDances")
	
	table.insert(scope, player.CharacterAdded:Connect(manageNewChar))
	if player.Character then
		manageNewChar(player.Character)
	end
	
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
	--manageRobloxDancesFrame()
end

return Emotes