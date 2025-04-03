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
			keybindMod.inputStarted(input, processed)
		end
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		for _, keybindMod in modulesHandler.requiredModules do
			if not table.find(keybindMod.Keys, input.KeyCode) then
				continue
			end
			keybindMod.inputEnded(input, processed)
		end
	end)
	
	player.CharacterAdded:Connect(function(character)
		modulesHandler:CallModulesFunction("characterAdded", character)
	end)
end

return KeybindController