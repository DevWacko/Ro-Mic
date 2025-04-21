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
local settingsService
local service

local loadedPlayers: { [number]: Player } = {}
local playerTroves: { [Player]: Trove.Trove } = {}

PlayTime.init = function()
	settingsService = Knit.GetService("SettingsService")
	service = Knit.GetService("PlayerDataService")
	
	task.spawn(function()
		while task.wait(60) do
			for _, player in loadedPlayers do
				service:UpdateValue(player, "PlayTime", function(value: string)
					return tostring(tonumber(value) + 1)
				end)
			end
		end
	end)
end

-- local function setPlayTime(player: Player, playtime: number?)
-- 	local leaderstats: Folder? = player:FindFirstChild("leaderstats")
-- 	if not leaderstats then
-- 		return
-- 	end
-- 	local val = leaderstats:FindFirstChild("PlayTime")
-- 	if val then
-- 		val.Value = playtime or service:GetValue(player, "PlayTime")
-- 	end
-- end

PlayTime.playerProfileLoaded = function(player: Player)
	table.insert(loadedPlayers, player)
	
	local _trove = Trove.new()
	-- _trove:Add(service:ObserveValue(player, "PlayTime", function(value: number)
	-- 	setPlayTime(player, value)
	-- end))
	
	local function handleHiding(hide: boolean)
		local playTimeVal: StringValue = player:WaitForChild("leaderstats"):FindFirstChild("PlayTime")
		if not playTimeVal then
			return
		end
		playTimeVal:SetAttribute("IgnoreChange", hide)
		playTimeVal.Value = if hide then "-" else service:GetValue(player, "PlayTime")
	end
	handleHiding(service:GetValue(player, "Settings")["HideMinutes"])
	_trove:Add(settingsService:ObserveSetting(player, "HideMinutes", function(hide: boolean)
		handleHiding(hide)
		-- if hide then
		-- 	service:CallModuleEvent(player, "Leaderstats", "ValueCustomDisplay", "PlayTime", "-")
		-- else
		-- 	service:CallModuleEvent(player, "Leaderstats", "RemoveValueCustomDisplay", "PlayTime")
		-- end
	end))
	playerTroves[player] = _trove
	
	--setPlayTime(player)
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