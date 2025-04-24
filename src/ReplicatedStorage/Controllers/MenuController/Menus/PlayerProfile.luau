-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Fusion = require(Packages.Fusion)
local Trove = require(Packages.Trove)
local Knit = require(Packages.Knit)

local peek = Fusion.peek

local Data = require(ReplicatedStorage.Source.Data.Interacting.PlayerProfiles)

-- Main Module --
local PlayerProfile = { MenuName = "PlayerProfile" }

-- Local --
local player = Players.LocalPlayer

local scope = Fusion:scoped()
local _trove = Trove.new()

local tempScope = Fusion:scoped()
table.insert(scope, tempScope)

local menu: ScreenGui
local mainFrame: Frame
local infoFrame: Frame
local actionButtonsFrame: Frame

local canClickOut = false

local voiceChatController
local controller

local interactingService
local playerDataService

PlayerProfile.init = function()
	voiceChatController = Knit.GetController("VoiceChatController")
	controller = Knit.GetController("MenuController")
	
	interactingService = Knit.GetService("InteractingService")
	playerDataService = Knit.GetService("PlayerDataService")
end

PlayerProfile.shown = function(targetPlayer: Player?, canClickOutToggle: boolean?)
	if not targetPlayer then
		return
	end
	if canClickOutToggle ~= nil then
		canClickOut = canClickOutToggle
	end
	PlayerProfile.playerViewing:set(targetPlayer)
end

PlayerProfile.closed = function(canClickOutToggle: boolean?)
	if canClickOutToggle ~= nil then
		canClickOut = canClickOutToggle
	end
	PlayerProfile.playerViewing:set(nil)
end

local function manageInfo()
	tempScope:Observer(PlayerProfile.playerViewing):onChange(function()
		local targetPlayer: Player = peek(PlayerProfile.playerViewing)
		infoFrame:FindFirstChild("DisplayName").Text = targetPlayer and targetPlayer.DisplayName or ""
		infoFrame:FindFirstChild("Username").Text = targetPlayer and `@{targetPlayer.Name}` or ""
		
		local avatarImageLabel: ImageLabel = infoFrame:FindFirstChild("PlayerAvatar"):FindFirstChild("Avatar")
		avatarImageLabel.Image = ""
		
		if targetPlayer then
			playerDataService:GetValueFromOther(targetPlayer, "Settings"):andThen(function(playerSettings)
				local bioText: string? = playerSettings.Bio
				
				local bioLabel: TextLabel = infoFrame:FindFirstChild("Bio"):FindFirstChild("Public")
				bioLabel.Visible = true
				bioLabel.Text = bioText and bioText or string.format(Data.Defaults.BioReplacment, targetPlayer.Name)
			end)
			
			local image: string?
			local success, err = pcall(function()
				image = Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
			end)
			if success and image then
				avatarImageLabel.Image = image
			else
				warn("There was an error getting avatar image: ", err)
			end
		end
	end)
end

local function manageActions()
	table.insert(tempScope, actionButtonsFrame:FindFirstChild("AddPlayer"):FindFirstChild("Add").MouseButton1Click:Connect(function()
		local targetPlayer: Player? = peek(PlayerProfile.playerViewing)
		if not targetPlayer or targetPlayer == player then
			return
		end
		StarterGui:SetCore("PromptSendFriendRequest", targetPlayer)
	end))
	table.insert(tempScope, actionButtonsFrame:FindFirstChild("CopyOutfit"):FindFirstChild("Clone").MouseButton1Click:Connect(function()
		local targetPlayer: Player? = peek(PlayerProfile.playerViewing)
		if not targetPlayer or targetPlayer == player  then
			return
		end
		interactingService:InteractAttempt("PlayerProfiles", "CloneOutfitAttempt", targetPlayer)
	end))
	table.insert(tempScope, actionButtonsFrame:FindFirstChild("MutePlayer"):FindFirstChild("MutePlayer").MouseButton1Click:Connect(function()
		local targetPlayer: Player? = peek(PlayerProfile.playerViewing)
		if not targetPlayer or targetPlayer == player  then
			return
		end
		voiceChatController:SetPlayerMuted(targetPlayer, not voiceChatController:IsMuted(targetPlayer))
	end))
end

local function manageClosing()
	local InSelection = false
	
	table.insert(scope, mainFrame.MouseEnter:Connect(function() InSelection = true end))
	table.insert(scope, mainFrame.MouseLeave:Connect(function() InSelection = false end))
	
	table.insert(scope, UserInputService.InputBegan:Connect(function(input)
		if mainFrame.Visible and not InSelection and input.UserInputType == Enum.UserInputType.MouseButton1 and canClickOut then
			controller:CloseMenu("PlayerProfile")
		end
	end))
	
	_trove:Add(controller:ObserveMenuClosing("PlayerProfile", function()
		InSelection = false
	end))
end

PlayerProfile.menuLoaded = function(loadedMenu: ScreenGui)
	tempScope:doCleanup()
	_trove:Clean()
	
	PlayerProfile.playerViewing = tempScope:Value(nil)
	
	menu = loadedMenu
	mainFrame = menu:FindFirstChild("Main")
	infoFrame = mainFrame:FindFirstChild("Info")
	actionButtonsFrame = mainFrame:FindFirstChild("Actions"):FindFirstChild("Buttons")
	
	manageClosing()
	manageActions()
	manageInfo()
end

return PlayerProfile