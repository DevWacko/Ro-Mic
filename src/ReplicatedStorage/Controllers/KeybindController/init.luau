-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Controller
local KeybindController = Knit.CreateController { Name = "KeybindController" }

-- Types --
type Self = typeof(KeybindController)

-- Local --
local player = Players.LocalPlayer

function KeybindController:KnitInit()
	local modulesHandler = ModuleHandler.new(script.Keybinds)
	UserInputService.InputBegan:Connect(function(input, processed)
		for _, keybindMod in modulesHandler.requiredModules do
			if not table.find(keybindMod.Keys, input.KeyCode) then
				continue
			end
			local inputStarted = keybindMod.inputStarted
			if inputStarted then
				inputStarted(input, processed)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		for _, keybindMod in modulesHandler.requiredModules do
			if not table.find(keybindMod.Keys, input.KeyCode) then
				continue
			end
			local inputEnded = keybindMod.inputEnded
			if inputEnded then
				inputEnded(input, processed)
			end
		end
	end)
	
	player.CharacterAdded:Connect(function(character)
		modulesHandler:CallModulesFunction("characterAdded", character)
	end)
end

return KeybindController