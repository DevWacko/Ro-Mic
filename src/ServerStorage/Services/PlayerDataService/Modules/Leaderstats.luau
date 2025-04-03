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

Leaderstats.playerProfileLoaded = function(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	for key, value in service.profiles[player].Data do
		if typeof(value) == "number" then
			local stat = Instance.new("NumberValue")
			stat.Name = key
			stat.Value = value
			stat.Parent = leaderstats
			
			stat.Changed:Connect(function(newValue)
				service.profiles[player].Data[key] = newValue
			end)
		end
	end
	
	service.PlayerValueChanged:Connect(function(otherPlayer: Player, key: string, value: any)
		if otherPlayer ~= player then
			return
		end
		local val: ValueBase? = leaderstats:FindFirstChild(key)
		if val then
			val.Value = value
		end
	end)
end

return Leaderstats