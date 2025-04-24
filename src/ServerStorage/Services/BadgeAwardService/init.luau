-- Services --
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Knit = require(Packages.Knit)

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Service --
local BadgeAwardService = Knit.CreateService { Name = "BadgeAwardService" }

-- Types --
type Self = typeof(BadgeAwardService)

function BadgeAwardService:AttemptBadgeAward(player: Player, id: number)
	-- Fetch badge information
	local success, badgeInfo = pcall(function()
		return BadgeService:GetBadgeInfoAsync(id)
	end)
	if success then
		-- Confirm that badge can be awarded
		if badgeInfo.IsEnabled then
			-- Award badge
			local awardSuccess, result = pcall(function()
				return BadgeService:AwardBadge(player.UserId, id)
			end)
			if not awardSuccess then
				-- the AwardBadge function threw an error
				warn("Error while awarding badge:", result)
			elseif not result then
				-- the AwardBadge function did not award a badge
				--warn("Failed to award badge.")
			end
		end
	else
		warn("Error while fetching badge info: " .. badgeInfo)
	end
end

function BadgeAwardService:KnitInit()
	local PlayerDataService = Knit.GetService("PlayerDataService")
	local moduleHandler = ModuleHandler.new(script.Badges)
	PlayerDataService.PlayerProfileLoaded:Connect(function(player: Player)
		moduleHandler:CallModulesFunction("playerProfileLoaded", player)
	end)
end

return BadgeAwardService