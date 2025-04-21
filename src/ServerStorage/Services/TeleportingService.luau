-- Services --
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PolicyService = game:GetService("PolicyService")
local TeleportService = game:GetService("TeleportService")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

local safeTeleport = require(ReplicatedStorage.Source.Utils.Player.safeTeleport)

-- Service --
local TeleportingService = Knit.CreateService { Name = "TeleportingService" }

-- Types --
type Self = typeof(TeleportingService)

-- Local --
local placeId = game.PlaceId

function TeleportingService.Client:SafeTeleportToServer(player: Player, serverId: string?)
	return self.Server:SafeTeleportToServer(player, serverId)
end

function TeleportingService:SafeTeleportToServer(player: Player, serverId: string?)
	local options = Instance.new("TeleportOptions")
	options.ServerInstanceId = serverId
	
	safeTeleport(placeId, { player }, options)
	
	return true
end

local function isPlayer17Plus(player)
	local success, policyInfo = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)

	if success and policyInfo then
		return policyInfo.IsVerified17Plus == true
	end

	return false
end

function TeleportingService:KnitInit()
	-- Players.PlayerAdded:Connect(function(player)
	-- 	task.delay(10, function()
	-- 		self:TeleportPlayerTo17PlusAttemt(player)
	-- 	end)
	-- end)
end

return TeleportingService