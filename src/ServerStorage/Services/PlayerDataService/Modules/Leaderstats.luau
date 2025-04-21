-- Packages --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Knit = require(ReplicatedStorage.ExPackages.Knit)

-- Main Module --
local Leaderstats = {}

-- Local --
local service

Leaderstats.init = function()
	service = Knit.GetService("PlayerDataService")
end

local function getValueFromType(valueType: any)
	if typeof(valueType) == "number" then
		return Instance.new("NumberValue")
	elseif typeof(valueType) == "string" then
		return Instance.new("StringValue")
	end
end

-- local function valueCustomDisplay(player: Player, valueName: string, value: any)
-- 	local leaderstats: Folder = player:FindFirstChild("leaderstats")
-- 	local realVal = leaderstats:FindFirstChild(valueName)
	
-- 	local stat = getValueFromType(value)
-- 	if stat then
-- 		stat.Name = valueName
-- 		stat.Value = value
-- 		stat.Parent = leaderstats
-- 	end
	
-- 	realVal:Destroy()
-- end

-- local function removeValueCustomDisplay(player: Player, valueName: string)
-- 	local value = service:GetValue(player, valueName)
-- 	if not value then
-- 		return
-- 	end
	
-- 	local leaderstats: Folder = player:FindFirstChild("leaderstats")
-- 	local customVal = leaderstats:FindFirstChild(valueName)
-- 	customVal:Destroy()
	
-- 	local stat = getValueFromType(value)
-- 	if stat then
-- 		stat.Name = valueName
-- 		stat.Value = value
-- 		stat.Parent = leaderstats
-- 	end
-- end

-- Leaderstats.eventCalled = function(player: Player, event: string, ...)
-- 	if event == "ValueCustomDisplay" then
-- 		return valueCustomDisplay(player, ...)
-- 	elseif event == "RemoveValueCustomDisplay" then
-- 		return removeValueCustomDisplay(player, ...)
-- 	end
-- end

Leaderstats.playerProfileLoaded = function(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	for key, value in service.profiles[player].Data do
		local stat = getValueFromType(value)
		if stat then
			stat.Name = key
			stat.Value = value
			stat.Parent = leaderstats
		end
	end
	
	service.PlayerValueChanged:Connect(function(otherPlayer: Player, key: string, value: any)
		if otherPlayer ~= player then
			return
		end
		local val: ValueBase? = leaderstats:FindFirstChild(key)
		if val and typeof(val.Value) == typeof(value) and not val:GetAttribute("IgnoreChange") then
			val.Value = value
		end
	end)
end

return Leaderstats