-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local peek = Fusion.peek

local Data = require(ReplicatedStorage.Source.Data.Interacting.PlayerProfiles)

-- Main Module --
local PlayerProfile = { MenuName = "PlayerProfile" }

-- Local --
local scope = Fusion:scoped()

local tempScope = Fusion:scoped()
table.insert(scope, tempScope)

local playerViewing: Fusion.Value<Player>?

local mainFrame: Frame
local infoFrame: Frame
local actionButtonsFrame: Frame

local interactingService

PlayerProfile.init = function()
	interactingService = Knit.GetService("InteractingService")
end

PlayerProfile.shown = function(menu: ScreenGui, targetPlayer: Player?)
	if not targetPlayer then
		return
	end
	playerViewing:set(targetPlayer)
end

local function manageInfo()
	tempScope:Observer(playerViewing):onChange(function()
		local targetPlayer: Player = peek(playerViewing)
		infoFrame:FindFirstChild("DisplayName").Text = targetPlayer and targetPlayer.DisplayName or ""
		infoFrame:FindFirstChild("Username").Text = targetPlayer and `@{targetPlayer.Name}` or ""
		
		local bioLabel: TextLabel = infoFrame:FindFirstChild("Bio"):FindFirstChild("Public")
		bioLabel.Visible = true
		bioLabel.Text = targetPlayer and string.format(Data.Defaults.BioReplacment, targetPlayer.Name) or ""
		
		local avatarImageLabel: ImageLabel = infoFrame:FindFirstChild("PlayerAvatar"):FindFirstChild("Avatar")
		avatarImageLabel.Image = ""
		
		local image: string?
		local success, err = pcall(function()
			image = Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
		end)
		if success and image then
			avatarImageLabel.Image = image
		else
			warn("There was an error getting avatar image: ", err)
		end
	end)
end

local function manageActions()
	table.insert(tempScope, actionButtonsFrame:FindFirstChild("AddPlayer"):FindFirstChild("Add").MouseButton1Click:Connect(function()
		local targetPlayer: Player? = peek(playerViewing)
		if not targetPlayer then
			return
		end
		StarterGui:SetCore("PromptSendFriendRequest", targetPlayer)
	end))
	table.insert(tempScope, actionButtonsFrame:FindFirstChild("CopyOutfit"):FindFirstChild("Clone").MouseButton1Click:Connect(function()
		local targetPlayer: Player? = peek(playerViewing)
		if not targetPlayer then
			return
		end
		interactingService:InteractAttempt("PlayerProfiles", "CloneOutfitAttempt", targetPlayer)
	end))
end

PlayerProfile.menuLoaded = function(menu: ScreenGui)
	tempScope:doCleanup()
	
	playerViewing = tempScope:Value(nil)
	
	mainFrame = menu:FindFirstChild("Main")
	infoFrame = mainFrame:FindFirstChild("Info")
	actionButtonsFrame = mainFrame:FindFirstChild("Actions"):FindFirstChild("Buttons")
	
	manageActions()
	manageInfo()
end

return PlayerProfile