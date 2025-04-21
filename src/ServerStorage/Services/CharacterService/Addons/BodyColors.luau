-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Modules --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

local ModuleData = require(ServerStorage:FindFirstChild("Source"):FindFirstChild("Data"):FindFirstChild("Character"):FindFirstChild("BodyColors"))

-- Main Module --
local BodyColors = {}

-- Local --
local tempScopes: { [Model]: Fusion.Scope } = {}

local playerColors: { [Player]: { [string]: Color3 } } = {}

local function setLimbColorAttempt(player: Player, limbName: string, color: Color3)
	local char: Model? = player.Character or player.CharacterAdded:Wait()
	if not char then
		return false
	end
	
	local bodyColors = char:FindFirstChildWhichIsA("BodyColors")
	if not bodyColors then
		return false
	end
	local limbColorKey = limbName .. "Color3"
	assert(bodyColors[limbColorKey] ~= nil, limbName .. " was not found in ".. player.Name .. "'s character")
	
	bodyColors[limbColorKey] = color
	
	if playerColors[player] then
		playerColors[player][limbName] = color
	end
	
	return true
end

local function loadPlayerColors(player: Player)
	for limbName, color in playerColors[player] do
		setLimbColorAttempt(player, limbName, color)
	end
end

BodyColors.onEventRecieved = function(player: Player, key: string, ...)
	local data = { ... }
	if key == "SetLimbColor" then
		local limbName = data[1]
		assert(limbName and typeof(limbName) == "string", "First parameter was not a string")
		
		local color = data[2]
		assert(color and typeof(color) == "Color3", "Second parameter was not a Color3")
		
		return task.spawn(setLimbColorAttempt, player, limbName, color)
	end
end

BodyColors.characterAdded = function(char: Model)
	local scope = Fusion:scoped()
	tempScopes[char] = scope
	
	local player = Players:GetPlayerFromCharacter(char)
	if playerColors[player] and ModuleData.SAVE_ON_RESET then
		loadPlayerColors(player)
	else
		playerColors[player] = {}
	end
end

BodyColors.characterRemoving = function(char: Model)
	if tempScopes[char] then
		tempScopes[char]:doCleanup()
		tempScopes[char] = nil
	end
end

return BodyColors