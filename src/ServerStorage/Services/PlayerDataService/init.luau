-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local PlayerDataTemplate = require(ServerStorage.Source.Data.Player.PlayerDataTemplate)

local Signal = require(ExPackages.Signal)
local Knit = require(ExPackages.Knit)

local ProfileStore = require(script.ProfileStore)

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Service --
local PlayerDataService = Knit.CreateService {
	Name = "PlayerDataService",
	Client = {
		ProfileLoaded = Knit.CreateSignal(),
		ValueChanged = Knit.CreateSignal(),
	}
}
PlayerDataService.PlayerProfileLoaded = Signal.new()
PlayerDataService.PlayerValueChanged = Signal.new()

-- Types --
type Self = typeof(PlayerDataService)

-- Local --
local playersData: { [Player]: { [string]: any } } = {}

local function warning(key: string, player: Player, ...)
	local data = {...}
	if key == "Key" then
		warn(`Failed to find the key: {data[1]} inside of `, player, "'s data")
	elseif key == "ValueType" then
		warn(`Failed to set a {data[1]} type to a {data[2]} type. Called for the player: `, player)
	elseif key == "Profile" then
		warn(player, "'s profile data has not loaded, or that player doesnt exist.")
	end
end

local function getPlayerData(player: Player)
	local playerData = playersData[player]
	if not playerData then
		return
	end
	return playerData
end

local function validKey(player: Player, key: string)
	if playersData[player][key] == nil then
		warning("Key", player, key)
		return false
	end
	return true
end

local function validValueMatch(player: Player, key: string, value: number)
	if not validKey(player, key) then
		return false
	end
	local requiredType, settingType = typeof(playersData[player][key]), typeof(value)
	if settingType ~= requiredType then
		warning("ValueType", player, settingType, requiredType)
		return false
	end
	return true
end

function PlayerDataService:CallModuleEvent(player: Player, moduleKey: string, eventName: string, ...)
	return self.modulesHandler.requiredModules[moduleKey].eventCalled(player, eventName, ...)
end

function PlayerDataService:ObserveValue(player: Player, key: string, callback: (newValue: any) -> ()): RBXScriptConnection
	return self.PlayerValueChanged:Connect(function(otherPlayer: Player, changedKey: string, changedValue: any)
		if otherPlayer ~= player or changedKey ~= key then
			return
		end
		callback(changedValue)
	end)
end

function PlayerDataService:SetValue(player: Player, key: string, value: any)
	local playerData = getPlayerData(player)
	if not playerData then
		return
	end
	
	if not validValueMatch(player, key, value) then
		return
	end
	
	local profiles = PlayerDataService.profiles
	if not profiles[player] then
		warning("Profile", player)
		return
	end
	
	profiles[player].Data[key] = value
	playerData[key] = value
	
	self.PlayerValueChanged:Fire(player, key, playerData[key])
	self.Client.ValueChanged:Fire(player, key, playerData[key])
end

function PlayerDataService.Client:GetValueFromOther(player: Player, otherPlayer: Player, key: string)
	return self.Server:GetValue(otherPlayer, key)
end
function PlayerDataService.Client:GetValue(player: Player, key: string)
	return self.Server:GetValue(player, key)
end
function PlayerDataService:GetValue(player: Player, key: string)
	assert(player:IsA("Player"), "Player parameter must be a Player")
	
	if not validKey(player, key) then
		return
	end
	return playersData[player][key]
end

function PlayerDataService:UpdateValue(player: Player, key: string, updateCallback: (currentValue: any) -> ())
	if not getPlayerData(player) then
		return
	end
	if not validKey(player, key) then
		return
	end
	
	local updatedValue = updateCallback(playersData[player][key])
	if not validValueMatch(player, key, updatedValue) then
		return
	end
	
	self:SetValue(player, key, updatedValue)
end

local function setupPlayerProfile(player: Player)
	local profile = PlayerDataService.playerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)
		
		profile.OnSessionEnd:Connect(function()
			PlayerDataService.profiles[player] = nil
			player:Kick(`Profile session end - Please rejoin`)
		end)
		if player.Parent == Players then
			PlayerDataService.profiles[player] = profile
			print(`Profile loaded for {player.DisplayName}!`)
			
			for key, value in PlayerDataService.profiles[player].Data do
				PlayerDataService:SetValue(player, key, value)
			end
			
			PlayerDataService.PlayerProfileLoaded:Fire(player)
			PlayerDataService.Client.ProfileLoaded:Fire(player)
		else
			profile:EndSession()
		end
	else
		-- This condition should only happen when the Roblox server is shutting down
		player:Kick(`Profile load fail - Please rejoin`)
	end
end

local function onPlayerAdded(player: Player)
	local newPlayerData = {}
	for key, value in PlayerDataTemplate.Values do
		newPlayerData[key] = value
	end
	playersData[player] = newPlayerData
	
	setupPlayerProfile(player)
end

local function onPlayerRemoving(player: Player)
	local profile = PlayerDataService.profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
	
	PlayerDataService.modulesHandler:CallModulesFunction("playerRemoving", player)
	
	playersData[player] = nil
end

function PlayerDataService:KnitInit()
	self.modulesHandler = ModuleHandler.new(script.Modules)
	self.PlayerProfileLoaded:Connect(function(player: Player)
		self.modulesHandler:CallModulesFunction("playerProfileLoaded", player)
	end)
	
	self.playerStore = ProfileStore.New("PlayerStore", PlayerDataTemplate.Values)
	self.profiles = {} :: {[Player]: typeof(self.PlayerStore:StartSessionAsync())}
	
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PlayerDataService