local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerController = Knit.CreateController { Name = "PlayerController" }

function PlayerController:PromptFriendsInvite()
	local player = Players.LocalPlayer

	-- Function to check whether the player can send an invite
	local function canSendGameInvite(sendingPlayer)
		local success, canSend = pcall(function()
			return SocialService:CanSendGameInviteAsync(sendingPlayer)
		end)
		return success and canSend
	end

	local canInvite = canSendGameInvite(player)
	if canInvite then
		SocialService:PromptGameInvite(player)
	end
end

function PlayerController:KnitStart()
	
end

function PlayerController:KnitInit()
	
end

return PlayerController