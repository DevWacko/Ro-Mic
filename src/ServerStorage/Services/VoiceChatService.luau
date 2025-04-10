-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

-- Service --
local VoiceChatService = Knit.CreateService { Name = "VoiceChatService" }

-- Types --
type Self = typeof(VoiceChatService)

function VoiceChatService:SetupCharacter(player: Player, char: Model)
	local micInput = Instance.new("AudioDeviceInput")
	micInput.Parent = player
	micInput.Player = player
	micInput.Name = "MicInput"
	
	local micEmitter = Instance.new("AudioEmitter")
	micEmitter.Parent = char
	
	micEmitter.AudioInteractionGroup = "MicGroup"
	
	local wire = Instance.new("Wire")
	wire.Parent = micInput
	wire.SourceInstance = micInput
	wire.TargetInstance = micEmitter
end
--[[
function VoiceChatService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAppearanceLoaded:Connect(function(char)
			self:SetupCharacter(player, char)
		end)
	end)
end
]]
return VoiceChatService