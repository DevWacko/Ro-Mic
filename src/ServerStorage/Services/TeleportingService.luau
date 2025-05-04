-- Services --
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PolicyService = game:GetService("PolicyService")
local TeleportService = game:GetService("TeleportService")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Knit = require(Packages.Knit)

local safeTeleport = require(ReplicatedStorage.Source.Utils.Player.safeTeleport)

-- Service --
local TeleportingService = Knit.CreateService {
	Name = "TeleportingService",
	Client = {
		Teleporting = Knit.CreateSignal()
	}
}

-- Types --
type Self = typeof(TeleportingService)

-- Local --
local placeId = game.PlaceId

local policyPlaceID = 71523961983451

function TeleportingService.Client:SafeTeleportToServer(player: Player, serverId: string?)
	return self.Server:SafeTeleportToServer(player, serverId)
end

function TeleportingService:SafeTeleportToServer(player: Player, serverId: string?)
	local options = Instance.new("TeleportOptions")
	options.ServerInstanceId = serverId
	
	self.Client.Teleporting:Fire(player, true)
	safeTeleport(placeId, { player }, options)
	
	return true
end
function TeleportingService.Client:TeleportTo17Plus(player: Player)
	return self.Server:TeleportTo17Plus(player)
end

function TeleportingService:TeleportTo17Plus(player: Player)
	self.Client.Teleporting:Fire(player, true)
	safeTeleport(policyPlaceID, { player })
end

function TeleportingService:KnitInit()
	-- Players.PlayerAdded:Connect(function(player)
	-- 	task.delay(10, function()
	-- 		self:TeleportPlayerTo17PlusAttemt(player)
	-- 	end)
	-- end)
end

return TeleportingService