-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

local MainData = require(ServerStorage.Source.Data.Character.AFKMode)

local peek = Fusion.peek

-- Main Module --
local AFKMode = {}

-- Local --
local playersLastMove: { [Player]: number } = {}

local savedPlayerFaces: { [Player]: string } = {}

local playerAfkData: { [Player]: {
	scope: Fusion.Scope,
	afk: Fusion.Value<boolean>,
	lastMove: number,
} } = {}

local animationService

AFKMode.init = function()
	animationService = Knit.GetService("AnimationService")
	
	RunService.Heartbeat:Connect(function()
		for player, lastMove in playersLastMove do
			local afk = playerAfkData[player].afk
			
			local goAfk = tick() - lastMove >= MainData.TIME_BEFORE_AFK
			if goAfk and not peek(afk) then
				afk:set(true)
			elseif not goAfk and peek(afk) then
				afk:set(false)
			end
		end
	end)
end

AFKMode.characterAdded = function(char: Model)
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return
	end
	
	local player = Players:GetPlayerFromCharacter(char)
	local afkData = playerAfkData[player]
	if not afkData then
		return
	end
	
	local scope = afkData.scope
	scope:doCleanup()
	
	table.insert(scope, hum.Jumping:Connect(function()
		playersLastMove[player] = tick()
	end))
	table.insert(scope, hum.Running:Connect(function(speed)
		if speed <= 0 then
			return
		end
		playersLastMove[player] = tick()
	end))
end

AFKMode.playerAdded = function(player: Player)
	local scope = Fusion:scoped()
	local afk = scope:Value(false)
	
	scope:Observer(afk):onChange(function()
		local isAfk = peek(afk)
		
		local char = player.Character
		if not char then
			return
		end
		local head = char:FindFirstChild("Head")
		if not head then
			return
		end
		
		local oldParticle: Attachment? = head:FindFirstChild("Zzz")
		if oldParticle then
			oldParticle:Destroy()
		end
		
		if isAfk then
			animationService:PlayAnimation(player, MainData.AFK_ANIMATION_PATH, true)
			ReplicatedStorage.Assets.Particles.AFK.Zzz:Clone().Parent = head
		else
			animationService:StopAnimation(player, MainData.AFK_ANIMATION_PATH)
		end
		
		local faceDecal = head:FindFirstChild("face")
		local savedFaceTexture = savedPlayerFaces[player]
		if not savedFaceTexture then
			savedPlayerFaces[player] = faceDecal.Texture
		end
		faceDecal.Texture = isAfk and MainData.FACE_TEXTURE or savedFaceTexture
	end)
	
	playersLastMove[player] = tick()
	
	playerAfkData[player] = {
		scope = Fusion:scoped(),
		afk = afk,
	}
end

AFKMode.playerRemoving = function(player: Player)
	playersLastMove[player] = nil
	
	playerAfkData[player].scope:doCleanup()
	playerAfkData[player] = nil
end

return AFKMode