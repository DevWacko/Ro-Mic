-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Modules --
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local ModuleData = require(ReplicatedStorage:FindFirstChild("Source"):FindFirstChild("Data"):FindFirstChild("Character"):FindFirstChild("BodyScales"))

-- Main Module --
local BodyScales = {}

-- Local --
local tempScopes: { [Model]: Fusion.Scope } = {}

local playerDefaultScales: { [Player]: { [string]: number } } = {}
local playerScales: { [Player]: { [string]: number } } = {}

local function setBodyTypeScale(player: Player, scaleType: string, newScale: number)
	local char: Model? = player.Character or player.CharacterAdded:Wait()
	if not char then
		return false
	end
	
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return
	end
	
	local range = ModuleData.ScalingRanges[scaleType]
	assert(range ~= nil, scaleType .. " was not a valid adjustable scale property")
	assert(newScale >= range.MIN and newScale <= range.MAX, "new scale was outside of range")
	
	local scaleVal: NumberValue = hum:FindFirstChild(scaleType)
	assert(scaleVal ~= nil, scaleType .. " was not found in ".. player.Name .. "'s character")
	
	scaleVal.Value = newScale
	if scaleType == "BodyHeightScale" then
		char:PivotTo(char:GetPivot() * CFrame.new(0, 2 * newScale, 0))
	end
	
	if playerScales[player] then
		playerScales[player][scaleType] = newScale
	end
	
	return true
end

local function loadPlayerScales(player: Player)
	for scaleType, scale in playerScales[player] do
		setBodyTypeScale(player, scaleType, scale)
	end
end

BodyScales.onEventRecieved = function(player: Player, key: string, ...)
	local data = { ... }
	if key == "SetBodyTypeScale" then
		local scaleType = data[1]
		assert(scaleType and typeof(scaleType) == "string", "First parameter was not a string")
		
		local scale = data[2]
		assert(scale and typeof(scale) == "number", "Second parameter was not a number")
		
		return task.spawn(setBodyTypeScale, player, scaleType, scale)
	elseif key == "ResetBodyScale" then
		local char = player.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then
			return
		end
		
		local defaultScales = playerDefaultScales[player]
		if not defaultScales then
			return
		end
		for scaleValName, scale in defaultScales do
			local val: NumberValue? = hum:FindFirstChild(scaleValName)
			if val ~= nil then
				setBodyTypeScale(player, scaleValName, scale)
				--val.Value = scale
			end
		end
	end
end

BodyScales.characterAdded = function(char: Model)
	local player = Players:GetPlayerFromCharacter(char)
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	
	if not table.find(playerDefaultScales, player) and hum then
		local scales = {}
		for scaleTypeName, _ in ModuleData.ScalingRanges do
			local scaleVal: NumberValue = hum:FindFirstChild(scaleTypeName)
			scales[scaleVal.Name] = scaleVal.Value
		end
		playerDefaultScales[player] = scales
	end
	
	local scope = Fusion:scoped()
	tempScopes[char] = scope
	
	if playerScales[player] and ModuleData.SAVE_ON_RESET then
		loadPlayerScales(player)
	else
		playerScales[player] = {}
	end
end

BodyScales.characterRemoving = function(char: Model)
	local player = Players:GetPlayerFromCharacter(char)
	if player then
		playerDefaultScales[player] = nil
		playerScales[player] = nil
	end
	if tempScopes[char] then
		tempScopes[char]:doCleanup()
		tempScopes[char] = nil
	end
end

return BodyScales