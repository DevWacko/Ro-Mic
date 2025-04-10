-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

-- Controller
local VoiceChatController = Knit.CreateController { Name = "VoiceChatController" }

-- Types --
type Self = typeof(VoiceChatController)

function VoiceChatController:SetupListener()
	local listener = Instance.new("AudioListener")
	listener.Parent = workspace.CurrentCamera
	listener.Name = "VoiceChatListener"
	
	local deviceOutput = Instance.new("AudioDeviceOutput")
	deviceOutput.Parent = listener
	deviceOutput.Player = Players.LocalPlayer
	
	local wire = Instance.new("Wire")
	wire.Parent = deviceOutput
	wire.SourceInstance = listener
	wire.TargetInstance = deviceOutput
	
	--listener.AudioInteractionGroup = "MicGroup"
end

function VoiceChatController:KnitInit()
	self:SetupListener()
end

return VoiceChatController