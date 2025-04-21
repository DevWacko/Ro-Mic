-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Service --
local CharacterService = Knit.CreateService { Name = "CharacterService" }

-- Types --
type Self = typeof(CharacterService)

function CharacterService.Client:SendAddonEventAttempt(player: Player, addonName: string, eventKey: string, ...)
	return self.Server:SendAddonEventAttempt(player, addonName, eventKey, ...)
end
function CharacterService:SendAddonEventAttempt(player: Player, addonName: string, eventKey: string, ...)
	assert(typeof(addonName) == "string", "Addon name is not of type string")
	assert(typeof(eventKey) == "string", "Event key is not of type string")
	
	local addonMod = self.moduleHandler.requiredModules[addonName]
	assert(addonMod ~= nil, addonName .. " was not found as a character addon")
	
	local onEventRecieved = addonMod.onEventRecieved
	assert(onEventRecieved ~= nil, addonName .. " is not recieving events")
	
	return onEventRecieved(player, eventKey, ...)
end

function CharacterService:KnitInit()
	self.moduleHandler = ModuleHandler.new(script.Addons)
	
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char: Model)
			self.moduleHandler:CallModulesFunction("characterAdded", char)
		end)
		player.CharacterRemoving:Connect(function(char: Model)
			self.moduleHandler:CallModulesFunction("characterRemoving", char)
		end)
	end)
end

return CharacterService