-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Knit = require(Packages.Knit)

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Service --
local StateService = Knit.CreateService { Name = "StateService" }

-- Types --
type Self = typeof(StateService)

function StateService:KnitInit()
	local moduleHandler = ModuleHandler.new(script.States)
	local function charAdded(char: Model)
		moduleHandler:CallModulesFunction("characterAdded", char)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(charAdded)
		if player.Character then
			charAdded(player.Character)
		end
		moduleHandler:CallModulesFunction("playerAdded", player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		moduleHandler:CallModulesFunction("playerRemoving", player)
	end)
end

return StateService