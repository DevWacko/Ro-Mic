-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages:FindFirstChild("Fusion"))
local Trove = require(ExPackages:FindFirstChild("Trove"))
local Knit = require(ExPackages:FindFirstChild("Knit"))

local peek = Fusion.peek

-- Main Module --
local PlayerProfiles = {
	Tag = "ViewableProfile",
}

-- Local --
local settingsService
local service

local playerHumanoidDescription: { [Player]: HumanoidDescription } = {}
local playerCloning: { [Player]: Fusion.Value<Player?> } = {}
local tempScopes: { [Player]: Fusion.Scope } = {}
local troves: { [Player]: Trove.Trove } = {}

PlayerProfiles.init = function()
	settingsService = Knit.GetService("SettingsService")
	service = Knit.GetService("InteractingService")
end

local function getCharStuff(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return
	end
	return char, hum
end

local function removeAllClonesOfPlayer(player: Player)
	for plr, cloneVal in playerCloning do
		if peek(cloneVal) == player then
			print("Removing cloning for player " .. plr.Name)
			cloneVal:set(nil)
		end
	end
end

local function managePlayerCloning(player: Player)
	local scope = Fusion:scoped()
	tempScopes[player] = scope
	
	local _trove = Trove.new()
	troves[player] = _trove
	
	local cloning: Fusion.Value<Player?> = scope:Value(nil)
	playerCloning[player] = cloning
	
	scope:Observer(cloning):onChange(function()
		local char, hum = getCharStuff(player)
		if not char or not hum then
			return
		end
		local targetPlayer = peek(cloning)
		if targetPlayer then
			local targetChar, targetHum = getCharStuff(targetPlayer)
			if not targetChar or not targetHum then
				return
			end
			local targetHumDesc = playerHumanoidDescription[targetPlayer]
			if not targetHumDesc then
				return
			end
			hum:ApplyDescription(targetHumDesc)
		else
			local humDesc = playerHumanoidDescription[player]
			if not humDesc then
				return
			end
			hum:ApplyDescription(humDesc)
		end
	end)
	
	_trove:Add(settingsService:ObserveSetting(player, "AllowAvatarCloning", function(allow)
		if not allow then
			cloning:set(nil)
			removeAllClonesOfPlayer(player)
		end
	end))
end

PlayerProfiles.playerAdded = function(player: Player)
	managePlayerCloning(player)
	
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
	
	removeAllClonesOfPlayer(player)
	
	if playerHumanoidDescription[player] then
		playerHumanoidDescription[player]:Destroy()
		playerHumanoidDescription[player] = nil
	end
	
	local scope = tempScopes[player]
	if scope then
		scope:doCleanup()
		tempScopes[player] = nil
	end
	local _trove = troves[player]
	if _trove then
		_trove:Destroy()
		troves[player] = nil
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
	
	if not settingsService:CheckSetting(targetPlayer, "AllowAvatarCloning") then
		return
	end
	
	playerCloning[player]:set(targetPlayer)
end

PlayerProfiles.sentInteractAttempt = function(player: Player, interaction: string, ...)
	
	if interaction == "ViewProfileAttempt" then
		return viewProfileAttempt(player, ...)
	elseif interaction == "CloneOutfitAttempt" then
		return cloneOutfitAttempt(player, ...)
	end
end

return PlayerProfiles