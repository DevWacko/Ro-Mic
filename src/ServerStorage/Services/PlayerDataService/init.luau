-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local PlayerDataTemplate = require(ServerStorage.Source.Data.PlayerDataTemplate)

local Signal = require(ExPackages.Signal)
local Trove = require(ExPackages.Trove)
local Knit = require(ExPackages.Knit)

-- Service --
local PlayerDataService = Knit.CreateService { Name = "PlayerDataService" }
PlayerDataService.ValueChanged = Signal.new()

-- Types --
type Self = typeof(PlayerDataService)

-- Local --
local playersData: { [Player]: { [string]: any } } = {}

local function warning(i: number, player: Player, ...)
	local data = {...}
	if i == 1 then
		warn(player, "'s has failed to load, or the player doesnt exist.")
	elseif i == 2 then
		warn(`Failed to find the key: {data[1]} inside of `, player, "'s data")
	elseif i == 3 then
		warn(`Failed to set a {data[1]} type to a {data[2]} type. Called for the player: `, player)
	end
end

local function getPlayerData(player: Player)
	local playerData = playersData[player]
	if not playerData then
		warning(1, player)
		return
	end
	return playerData
end

local function validKey(player: Player, key: string)
	if playersData[player][key] == nil then
		warning(2, player, key)
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
		warning(3, player, settingType, requiredType)
		return false
	end
	return true
end

function PlayerDataService:ObserveValue(player: Player, key: string, callback: (newValue: any) -> ()): RBXScriptConnection
	return self.ValueChanged:Connect(function(otherPlayer: Player, changedKey: string, changedValue: any)
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
	
	playerData[key] = value
	self.ValueChanged:Fire(player, key, playerData[key])
end

function PlayerDataService:GetValue(player: Player, key: string)
	if not validKey(player, key) then
		return
	end
	return playersData[player][key]
end

function PlayerDataService:UpdateValue(player: Player, key: string, updateCallback: (currentValue: any) -> ())
	if not validKey(player, key) then
		return
	end
	
	local updatedValue = updateCallback(playersData[player][key])
	if not validValueMatch(player, key, updatedValue) then
		return
	end
	
	self:SetValue(player, key, updatedValue)
end

local function onPlayerAdded(player: Player)
	local newPlayerData = {}
	for key, value in PlayerDataTemplate.Values do
		newPlayerData[key] = value
	end
	playersData[player] = newPlayerData
end

local function onPlayerRemoving(player: Player)
	playersData[player] = nil
end

function PlayerDataService:KnitInit()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PlayerDataService