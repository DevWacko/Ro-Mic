-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

local ModuleHandler = require(ReplicatedStorage:WaitForChild("Source"):FindFirstChild("Classes"):FindFirstChild("ModuleHandler"))

-- Controller
local SettingsController = Knit.CreateController { Name = "SettingsController" }

-- Types --
type Self = typeof(SettingsController)

function SettingsController:KnitInit()
	local moduleHandler = ModuleHandler.new(script.Settings)
	
	local settingsService = Knit.GetService("SettingsService")
	settingsService.SettingSet:Connect(function(settingName: string, newValue: any?)
		local settingMod = moduleHandler.requiredModules[settingName]
		if not settingMod then
			return
		end
		local valueSet = settingMod.valueSet
		if valueSet then
			valueSet(newValue)
		end
	end)
end

return SettingsController