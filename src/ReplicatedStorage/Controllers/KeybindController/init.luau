-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

local ModuledScriptHandler = require(ReplicatedStorage.Source.Classes.ModuledScriptHandler)

-- Controller
local KeybindController = Knit.CreateController { Name = "KeybindController" }

-- Types --
type Self = typeof(KeybindController)

function KeybindController:KnitInit()
	local modulesHandler = ModuledScriptHandler.new(script.Keybinds)
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
			keybindMod.InputEnded(input, processed)
		end
	end)
end

return KeybindController