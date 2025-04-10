-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Streamable = require(ExPackages.Streamable).Streamable
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local peek = Fusion.peek

-- Controller
local VoiceChatController = Knit.CreateController { Name = "VoiceChatController" }

-- Types --
type Self = typeof(VoiceChatController)

-- Local --
local scope = Fusion:scoped()

local playersData: { [Player]: {
	scope: Fusion.Scope,
	muted: Fusion.Value<boolean>,
} } = {}

function VoiceChatController:SetPlayerMuted(player: Player, muted: boolean)
	local playerData = playersData[player]
	if playerData then
		playerData.muted:set(muted)
	end
end

function VoiceChatController:IsMuted(player: Player)
	local playerData = playersData[player]
	if playerData then
		return peek(playerData.muted)
	end
end

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

function VoiceChatController:ManageNewPlayer(newPlayer: Player)
	local tempScope = Fusion:scoped()
	table.insert(scope, tempScope)
	
	local muted: Fusion.Value<boolean> = tempScope:Value(false)
	
	local charPrimary: BasePart?
	
	local connectorWeld: Weld?
	local voiceBox: Part?
	
	local function checkMuted()
		local char = newPlayer.Character
		if not char or not charPrimary or not voiceBox or not connectorWeld then
			return
		end
		if peek(muted) then
			connectorWeld.Part1 = nil
			voiceBox.Anchored = true
			voiceBox:PivotTo(CFrame.new(1000, 1000, 1000))
		else
			voiceBox:PivotTo(char:GetPivot())
			voiceBox.Anchored = false
			connectorWeld.Part1 = charPrimary
		end
	end
	checkMuted()
	
	tempScope:Observer(muted):onBind(function()
		checkMuted()
	end)
	
	local function manageChar(char: Model)
		local streamable = Streamable.new(char, "VoiceBox")
		table.insert(tempScope, streamable)
		
		streamable.primary(char):Observe(function(primary)
			charPrimary = primary
			checkMuted()
		end)
		streamable:Observe(function(streamingVoiceBox: Part, trove)
			voiceBox = streamingVoiceBox
			trove:Add(streamable.new(streamingVoiceBox, "Weld"):Observe(function(streamingConnectorWeld: Weld)
				connectorWeld = streamingConnectorWeld
			end))
			checkMuted()
		end)
	end
	table.insert(tempScope, newPlayer.CharacterAdded:Connect(manageChar))
	if newPlayer.Character then
		manageChar(newPlayer.Character)
	end
	
	playersData[newPlayer] = {
		scope = tempScope,
		muted = muted,
	}
end

function VoiceChatController:KnitInit()
	Players.PlayerAdded:Connect(function(playerAdded)
		self:ManageNewPlayer(playerAdded)
	end)
	Players.PlayerRemoving:Connect(function(playerRemoving)
		playersData[playerRemoving].scope:doCleanup()
		playersData[playerRemoving] = nil
	end)
	for _, existingPlayer in Players:GetPlayers() do
		self:ManageNewPlayer(existingPlayer)
	end
	
	self:SetupListener()
	
	-- task.delay(5, function()
	-- 	print(1)
	-- 	self:SetPlayerMuted(Players.LocalPlayer, true)
	-- 	task.wait(2)
	-- 	self:SetPlayerMuted(Players.LocalPlayer, false)
	-- end)
end

return VoiceChatController