-- Services --
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages
local Animations = ReplicatedStorage.Assets.Animations

-- Modules --
local Knit = require(ExPackages.Knit)

local getAnimationFromPath = require(ReplicatedStorage.Source.Utils.Character.getAnimationFromPath)

-- Service --
local AnimationService = Knit.CreateService { Name = "AnimationService" }

-- Types --
type Self = typeof(AnimationService)

-- Local --
local controllerIds: { [string]: AnimationController } = {}
local controllerTracks: { [string]: { [string]: AnimationTrack } } = {}

function getPlayerAnimator(player: Model): Animator?
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return
	end
	return hum:FindFirstChildWhichIsA("Animator")
end

function AnimationService.Client:PlayAnimationAttempt(player: Player, path: string, looped: boolean?)
	return self.Server:PlayAnimation(player, path, looped)
end

function AnimationService:PlayAnimation(player: Player, path: string, looped: boolean?)
	if not path or typeof(path) ~= "string" then
		warn("Path parameter must be a string")
		return
	end
	if looped ~= nil and typeof(looped) ~= "boolean" then
		warn("Looped parameter must be a boolean")
		return
	end
	
	local animator = getPlayerAnimator(player)
	if not animator then
		return
	end
	
	for _, oldTrack in animator:GetPlayingAnimationTracks() do
		oldTrack:Stop()
	end
	
	local track = animator:LoadAnimation(getAnimationFromPath(path))
	if looped then
		track.Looped = true
	end
	track:Play()
	
	controllerTracks[animator:GetAttribute("Id")][path] = track
end

function AnimationService.Client:StopAnimationAttempt(player: Player, path: string)
	return self.Server:StopAnimation(player, path)
end

function AnimationService:StopAnimation(player: Player, path: string)
	local animator = getPlayerAnimator(player)
	if not animator then
		return
	end
	
	local track = controllerTracks[animator:GetAttribute("Id")][path]
	if track then
		track:Stop()
		controllerTracks[animator:GetAttribute("Id")][path] = nil
	end
end

function AnimationService.Client:TrackIsPlaying(player: Player, path: string)
	return self.Server:TrackIsPlaying(player, path)
end

function AnimationService:TrackIsPlaying(player: Player, path: string)
	if not path or typeof(path) ~= "string" then
		warn("Path parameter must be a string")
		return false
	end
	
	local animator = getPlayerAnimator(player)
	if not animator then
		return false
	end
	
	return controllerTracks[animator:GetAttribute("Id")][path] ~= nil
end

function AnimationService:SetupNewCharacter(player: Player, char: Model)
	local animator = getPlayerAnimator(player)
	if not animator then
		return
	end
	
	local id = HttpService:GenerateGUID()
	animator:SetAttribute("Id", id)
	controllerIds[id] = animator
	
	controllerTracks[id] = {}
end

function AnimationService:ManageCharacterRemoving(player: Player, char: Model)
	local animator = getPlayerAnimator(player)
	if not animator then
		return
	end
	
	local id = animator:GetAttribute("Id")
	if controllerIds[id] then
		controllerIds[id] = nil
	end
	if controllerTracks[id] then
		controllerTracks[id] = nil
	end
end

function AnimationService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char: Model)
			self:SetupNewCharacter(player, char)
		end)
		player.CharacterRemoving:Connect(function(char: Model)
			self:ManageCharacterRemoving(player, char)
		end)
	end)
end

return AnimationService