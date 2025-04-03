-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Streamable = require(ExPackages.Streamable).Streamable
local Knit = require(ExPackages.Knit)

-- Controller
local RagdollController = Knit.CreateController { Name = "RagdollController" }

-- Types --
type Self = typeof(RagdollController)

-- Local --
local player = Players.LocalPlayer

local function onCharacterAdded(char: Model)
	local humStream
	humStream = Streamable.new(char, "Humanoid"):Observe(function(hum: Humanoid, trove)
		trove:Add(hum.Died:Once(function()
			RagdollController.RagdollService:ResetAttempt()
			humStream:Destroy()
		end))
	end)
end

function RagdollController:KnitInit()
	self.RagdollService = Knit.GetService("RagdollService")
	
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

return RagdollController