-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage:WaitForChild("ExPackages")

-- Modules --
local Fusion = require(ExPackages:FindFirstChild("Fusion"))
local Knit = require(ExPackages:FindFirstChild("Knit"))

local OnEvent = Fusion.OnEvent

local handleSettingObject = require(script.Parent.handleSettingObject)

-- Local --
local scope: Fusion.Scope

local settingsFrame: Frame

local settingsService

local function manageSettings()
	local categoryFrames: { Frame } = {}
	for _, categoryFrame: Frame? in settingsFrame:FindFirstChild("Contents"):GetChildren() do
		if not categoryFrame:IsA("Frame") then
			continue
		end
		table.insert(categoryFrames, categoryFrame)
	end
	for _, categoryFrame in categoryFrames do
		for _, settingObject: Instance in categoryFrame:GetChildren() do
			local settingType = settingObject:GetAttribute("SettingType")
			if not settingType then
				continue
			end
			handleSettingObject(scope, settingObject, settingsService)
		end
	end
end

local function manageSettingsFrame(tempScope: Fusion.Scope, mainFrame: Frame)
	scope = tempScope
	
	settingsFrame = mainFrame:FindFirstChild("Settings")
	
	settingsService = Knit.GetService("SettingsService")
	
	settingsService.SettingsLoaded:Connect(manageSettings)
end

return manageSettingsFrame