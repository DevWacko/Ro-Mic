-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Modules --
local Badges = require(ServerStorage.Source.Data.Reward.Badges)

local Knit = require(ReplicatedStorage.ExPackages.Knit)

-- Main Module --
local PlayTime = {}

-- Local --
local playerDataService
local service

PlayTime.init = function()
	playerDataService = Knit.GetService("PlayerDataService")
	service = Knit.GetService("BadgeAwardService")
end

local function attemptBadge(player: Player, value: string)
	for _, data in Badges.PlayTime do
		if tonumber(value) < data.Required then
			continue
		end
		service:AttemptBadgeAward(player, data.Id)
	end
end

PlayTime.playerProfileLoaded = function(player: Player)
	attemptBadge(player, playerDataService:GetValue(player, "PlayTime"))
	playerDataService:ObserveValue(player, "PlayTime", function(value: string)
		attemptBadge(player, value)
	end)
end

return PlayTime