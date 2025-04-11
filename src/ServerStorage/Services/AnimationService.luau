-- Services --
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages
local Animations = ReplicatedStorage.Assets.Animations

-- Modules --
local Knit = require(ExPackages.Knit)

-- Service --
local AnimationService = Knit.CreateService { Name = "AnimationService" }

-- Types --
type Self = typeof(AnimationService)

-- Local --
local controllerIds: { [string]: AnimationController } = {}
local controllerTracks: { [string]: { [string]: AnimationTrack } } = {}

function AnimationService:GetAnimationFromPath(path: string)
	local animation: Animation = Animations
	for _, pathPoint in string.split(path, "/") do
		animation = animation:FindFirstChild(pathPoint)
		if animation == nil then
			warn("Animation not found at path: " .. path)
		end
	end
	return animation
end

function getPlayerAnimator(player: Model)
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

function AnimationService:PlayAnimation(player: Player, path: string)
	local animator = getPlayerAnimator(player)
	if not animator then
		return
	end
	
	local track = animator:LoadAnimation(self:GetAnimationFromPath(path))
	track:Play()
	
	controllerTracks[animator:GetAttribute("Id")][path] = track
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