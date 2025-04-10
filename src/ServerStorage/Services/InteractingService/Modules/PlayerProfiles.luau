-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Knit = require(ReplicatedStorage.ExPackages.Knit)

-- Main Module --
local PlayerProfiles = {
	Tag = "ViewableProfile",
}

-- Local --
local service

local playerHumanoidDescription: { [Player]: HumanoidDescription } = {}

PlayerProfiles.init = function()
	service = Knit.GetService("InteractingService")
end

PlayerProfiles.playerAdded = function(player: Player)
	local function charAdded(char: Model)
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		hum.Died:Once(function()
			player:RemoveTag(PlayerProfiles.Tag)
		end)
		player:AddTag(PlayerProfiles.Tag)
		
		local desc = hum:FindFirstChildWhichIsA("HumanoidDescription")
		if not playerHumanoidDescription[player] and desc then
			playerHumanoidDescription[player] = desc:Clone()
		end
	end
	player.CharacterAdded:Connect(charAdded)
end

PlayerProfiles.playerRemoving = function(player: Player)
	player:RemoveTag(PlayerProfiles.Tag)
	
	if playerHumanoidDescription[player] then
		playerHumanoidDescription[player]:Destroy()
		playerHumanoidDescription[player] = nil
	end
end

local function validTargetPlayer(player: Player)
	return player and typeof(player) == "Instance" and player:IsA("Player") and player:HasTag(PlayerProfiles.Tag)
end

local function viewProfileAttempt(player: Player, targetPlayer: Player)
	if not validTargetPlayer(targetPlayer) then
		return
	end
	
	-- TODO: ADD PROFILE VIEWING CONDITIONS HERE
	
	return true
end

local function cloneOutfitAttempt(player: Player, targetPlayer: Player)
	if not validTargetPlayer(targetPlayer) then
		return
	end
	
	local char: Model?, targetChar: Model? = player.Character, targetPlayer.Character
	if not char or not targetChar then
		return
	end
	local hum, targetHum = char:FindFirstChildWhichIsA("Humanoid"), targetChar:FindFirstChildWhichIsA("Humanoid")
	if not hum or hum.Health <= 0 or not targetHum or targetHum.Health <= 0 then
		return
	end
	
	local targetHumDesc = playerHumanoidDescription[targetPlayer]
	if not targetHumDesc then
		return
	end
	
	-- TODO: ADD CONDITIONS FOR CHARACTER CLONING HERE
	
	hum:ApplyDescription(targetHumDesc)
end

local function mutePlayerAttempt(player: Player, targetPlayer: Player)
	if not validTargetPlayer(targetPlayer) then
		return
	end
	
	--voiceChatSDK.mutePlayerAsync(targetPlayer)
end

PlayerProfiles.sentInteractAttempt = function(player: Player, interaction: string, ...)
	if interaction == "ViewProfileAttempt" then
		return viewProfileAttempt(player, ...)
	elseif interaction == "CloneOutfitAttempt" then
		return cloneOutfitAttempt(player, ...)
	elseif interaction == "MutePlayerAttempt" then
		return mutePlayerAttempt(player, ...)
	end
end

return PlayerProfiles