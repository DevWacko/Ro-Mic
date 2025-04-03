-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Trove = require(ExPackages.Trove)
local Knit = require(ExPackages.Knit)

-- Main Module --
local PlayTime = {}

-- Local --
local service

local loadedPlayers: { [number]: Player } = {}
local playerTroves: { [Player]: Trove.Trove } = {}

PlayTime.init = function()
	service = Knit.GetService("PlayerDataService")
	task.spawn(function()
		while task.wait(60) do
			for _, player in loadedPlayers do
				service:UpdateValue(player, "PlayTime", function(value: number)
					return value + 1
				end)
			end
		end
	end)
end

local function setPlayTime(player: Player, playtime: number?)
	local leaderstats: Folder? = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local val = leaderstats:FindFirstChild("PlayTime")
	if val then
		val.Value = playtime or service:GetValue(player, "PlayTime")
	end
end

PlayTime.playerProfileLoaded = function(player: Player)
	table.insert(loadedPlayers, player)
	
	local _trove = Trove.new()
	_trove:Add(service:ObserveValue(player, "PlayTime", function(value: number)
		setPlayTime(player, value)
	end))
	playerTroves[player] = _trove
	
	setPlayTime(player)
end

PlayTime.playerRemoving = function(player: Player)
	local index = table.find(loadedPlayers, player)
	if index then
		table.remove(loadedPlayers, index)
	end
	
	local trove = playerTroves[player]
	if trove then
		trove:Destroy()
		playerTroves[player] = nil
	end
end

return PlayTime