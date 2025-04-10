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
	local voiceBox = Instance.new("Part")
	voiceBox.Name = "VoiceBox"
	voiceBox.CFrame = char:GetPivot()
	voiceBox.CanCollide = false
	voiceBox.Transparency = 1
	voiceBox.Size = Vector3.one
	
	local weld = Instance.new("Weld")
	weld.Part0 = voiceBox
	weld.Part1 = char.PrimaryPart
	weld.Parent = weld.Part0
	
	local micInput = Instance.new("AudioDeviceInput")
	micInput.Parent = voiceBox
	micInput.Player = player
	micInput.Name = "MicInput"
	
	local micEmitter = Instance.new("AudioEmitter")
	micEmitter.Parent = voiceBox
	
	micEmitter.AudioInteractionGroup = "MicGroup"
	
	local wire = Instance.new("Wire")
	wire.Parent = micInput
	wire.SourceInstance = micInput
	wire.TargetInstance = micEmitter
	
	voiceBox.Parent = char
end

function VoiceChatService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAppearanceLoaded:Connect(function(char)
			self:SetupCharacter(player, char)
		end)
	end)
end

return VoiceChatService