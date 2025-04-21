-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ToolsContainer = ReplicatedStorage:FindFirstChild("Assets"):FindFirstChild("Tools")

-- Modules --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

-- Main Module --
local Tools = {}

-- Local --
local tempScopes: { [Model]: Fusion.Scope } = {}

local function equipToolAttempt(player: Player, char: Model, categoryName: string, toolName: string)
	local categoryFold: Folder = ToolsContainer:FindFirstChild(categoryName)
	assert(categoryFold, categoryName .. " was not found as a tool category folder")
	
	local tool: Tool = categoryFold:FindFirstChild(toolName)
	assert(tool, toolName .. " was not found as a tool for ".. categoryFold.Name)
	
	if player:FindFirstChild("Backpack"):FindFirstChild(toolName) or char:FindFirstChild(toolName) then
		return false
	end
	
	tool:Clone().Parent = player:FindFirstChild("Backpack")
	
	return true
end

local function unequipToolAttempt(player: Player, char: Model, toolName: string)
	local tool: Tool? = player:FindFirstChild("Backpack"):FindFirstChild(toolName) or char:FindFirstChild(toolName)
	if tool then
		tool:Destroy()
		return true
	end
	return false
end

local function bulkUnequipTools(player: Player, char: Model, toolsToUnequip: { string })
	for _, toolName in toolsToUnequip do
		assert(typeof(toolName) == "string", "tool name was not a string")
		unequipToolAttempt(player, char, toolName)
	end
	return true
end

Tools.onEventRecieved = function(player: Player, key: string, ...)
	local data = { ... }
	
	local requiresToolName = key == "EquipTool" or key == "UnequipTool"
	
	local itemName = data[1]
	if requiresToolName then
		assert(itemName and typeof(itemName) == "string", "item name was nil or not a string")
	end
	
	local char = player.Character
	assert(char, player.Name .. "'s character was not found")
	
	if key == "EquipTool" then
		local categoryName = data[2]
		assert(categoryName and typeof(categoryName) == "string", "category name was nil or not a string")
		return equipToolAttempt(player, char, categoryName, itemName)
	elseif key == "UnequipTool" then
		return unequipToolAttempt(player, char, itemName)
	elseif key == "BulkUnequipTools" then
		return bulkUnequipTools(player, char, data[1])
	end
end

Tools.characterAdded = function(char: Model)
	local scope = Fusion:scoped()
	tempScopes[char] = scope
end

Tools.characterRemoving = function(char: Model)
	if tempScopes[char] then
		tempScopes[char]:doCleanup()
		tempScopes[char] = nil
	end
end

return Tools