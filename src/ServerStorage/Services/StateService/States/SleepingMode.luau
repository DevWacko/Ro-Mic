-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

local peek = Fusion.peek

-- Main Module --
local SleepingMode = {}

-- Local --
local playerSleepingData: { [Player]: {
	scope: Fusion.Scope,
	sleeping: Fusion.Value<boolean>,
	timeSinceLastMove: Fusion.Value<number>,
} } = {}

SleepingMode.characterAdded = function(char: Model)
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return
	end
	
	local player = Players:GetPlayerFromCharacter(char)
	local sleepingData = playerSleepingData[player]
	if not sleepingData then
		return
	end
	
	local scope = sleepingData.scope
	scope:doCleanup()
	
	local lastMoveTime = sleepingData.lastMove
	table.insert(scope, hum.Jumping:Connect(function()
		lastMoveTime:set(tick())
	end))
	table.insert(scope, hum.Running:Connect(function(speed)
		if speed <= 0 then
			return
		end
		lastMoveTime:set(tick())
	end))
end

SleepingMode.playerAdded = function(player: Player)
	local scope = Fusion:scoped()
	local sleeping = scope:Value(false)
	local lastMove = scope:Value(tick())
	
	scope:Observer(lastMove):onChange(function()
		if tick() - peek(lastMove) < 10 then
			return
		end
		print("AFK")
	end)
	
	playerSleepingData[player] = {
		scope = Fusion:scoped(),
		sleeping = sleeping,
		lastMove = lastMove,
	}
end

SleepingMode.playerRemoving = function(player: Player)
	playerSleepingData[player].scope:doCleanup()
	playerSleepingData[player] = nil
end

return SleepingMode