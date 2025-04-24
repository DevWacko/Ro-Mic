-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Fusion = require(Packages.Fusion)
local Signal = require(Packages.Signal)
local Knit = require(Packages.Knit)

local peek = Fusion.peek

local moduleHandler = require(ReplicatedStorage:FindFirstChild("Source"):FindFirstChild("Classes"):FindFirstChild("ModuleHandler"))

-- Service --
local SettingsService = Knit.CreateService {
	Name = "SettingsService",
	Client = {
		SettingsLoaded = Knit.CreateSignal(),
		SettingSet = Knit.CreateSignal(),
	},
}
SettingsService.PlayerSettingsLoaded = Signal.new()
SettingsService.SettingSet = Signal.new()

-- Types --
type Self = typeof(SettingsService)

-- Local --
local tempScopes: { [Player]: Fusion.Scope } = {}

local playerDataService

function SettingsService:ObserveSetting(player: Player, settingName: string, handler: (newValue: any) -> ())
	return self.SettingSet:Connect(function(otherPlayer: Player, otherSettingName: string, value: any)
		if otherPlayer ~= player or otherSettingName ~= settingName then
			return
		end
		handler(value)
	end)
end

function SettingsService:GetPlayerSettingValue(player: Player, settingName: string)
	local tries = 0
	repeat
		task.wait(1)
		tries += 1
	until self.playerSettingValues[player] or tries > 10
	
	local playerSettings = self.playerSettingValues[player]
	assert(playerSettings, "PlayerSettings has not been created for " .. player.Name)
	
	local playerSettingValue: Fusion.Value<any> = playerSettings[settingName]
	assert(playerSettingValue, settingName .. " has not been added to " .. player.Name)
	
	return playerSettingValue
end

function SettingsService.Client:CheckSetting(...)
	return self.Server:CheckSetting(...)
end
function SettingsService:CheckSetting(player: Player, settingName: string)
	local playerSettingValue = self:GetPlayerSettingValue(player, settingName)
	return if playerSettingValue ~= nil then peek(playerSettingValue) else nil
end

function SettingsService.Client:SetSettingAttempt(...)
	return self.Server:SetSettingAttempt(...)
end
function SettingsService:SetSettingAttempt(player: Player, settingName: string, value: any?)
	assert(settingName and typeof(settingName) == "string", "the setting name was nil or not a string")
	
	local settingMod = self.moduleHandler.requiredModules[settingName]
	assert(settingMod, settingName .. " was not a supported setting")
	
	local setSettingAttempt = settingMod.setSettingAttempt
	assert(setSettingAttempt, settingName .. " is not settable")
	
	local playerSettingValue = self:GetPlayerSettingValue(player, settingName)
	if not playerSettingValue then
		return false
	end
	
	local playerDebounces: { [Player]: boolean }? = settingMod.PlayerDebounces
	if playerDebounces and playerDebounces[player] then
		return false
	end
	
	local success, newValue = setSettingAttempt(player, value)
	if success then
		playerSettingValue:set(newValue)
	end
	
	return success, newValue
end

function SettingsService:ManageNewPlayer(player: Player)
	local scope = Fusion:scoped()
	
	local playerSettingValues = {}
	
	local function fire(settingName, value)
		self.Client.SettingSet:Fire(player, settingName, value)
		self.SettingSet:Fire(player, settingName, value)
	end
	
	for settingName, settingMod in self.moduleHandler.requiredModules do
		local loadedValue = playerDataService:GetValue(player, "Settings")[settingName]
		local defaultValue = if loadedValue ~= nil then loadedValue else settingMod.DefaultValue
		if defaultValue == nil then
			continue
		end
		
		local function updateAttempt(newValue)
			local updated = settingMod.updated
			if updated then
				updated(player, newValue)
			end
		end
		
		local value = scope:Value(defaultValue)
		scope:Observer(value):onChange(function()
			local newValue = peek(value)
			
			updateAttempt(newValue)
			
			playerDataService:UpdateValue(player, "Settings", function(newSettings)
				newSettings[settingName] = newValue
				return newSettings
			end)
			
			fire(settingName, newValue)
		end)
		playerSettingValues[settingName] = value
		
		updateAttempt(defaultValue)
		fire(settingName, defaultValue)
	end
	
	self.playerSettingValues[player] = playerSettingValues
	tempScopes[player] = scope
	
	self.PlayerSettingsLoaded:Fire(player)
	self.Client.SettingsLoaded:Fire(player)
end

function SettingsService:ManageRemovingPlayer(player: Player)
	local scope = tempScopes[player]
	if scope then
		scope:doCleanup()
		tempScopes[player] = nil
	end
	
	if self.playerSettingValues[player] then
		self.playerSettingValues[player] = nil
	end
end

function SettingsService:KnitInit()
	self.moduleHandler = moduleHandler.new(script.Settings)
	self.playerSettingValues = {} :: { [Player]: { [string]: Fusion.Value<any> } }
	
	playerDataService = Knit.GetService("PlayerDataService")
	playerDataService.PlayerProfileLoaded:Connect(function(player)
		self:ManageNewPlayer(player)
		self.moduleHandler:CallModulesFunction("playerAdded", player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.moduleHandler:CallModulesFunction("playerRemoving", player)
		self:ManageRemovingPlayer(player)
	end)
end

return SettingsService