-- Services --
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

local Data = require(ReplicatedStorage.Source.Data.Player.Memory)

-- Service --
local MemoryService = Knit.CreateService {
	Name = "MemoryService",
	Client = {
		ServersUpdated = Knit.CreateSignal(),
	},
}

-- Types --
type Self = typeof(MemoryService)

-- Local --
local serverMaps: { [string]: MemoryStoreSortedMap } = {}

local serverId = RunService:IsStudio() and -1 or game.JobId

function MemoryService:GetServerInfo()
	local url = "http://ip-api.com/json/"
	local getasyncinfo = HttpService:GetAsync(url) -- roblox server will get info from that link
	
	local players = {}
	for _, player: Player in Players:GetPlayers() do
		table.insert(players, player.UserId)
	end
	
	local placeVersion = game.PlaceVersion
	local major = 0
	local minor = math.floor(placeVersion / 1000) % 1000
	local patch = math.floor(placeVersion / 100) % 10
	local build = placeVersion % 100
	
	local formattedVersion = string.format("Server Version : %d.%d.%d.%d", major, minor, patch, build)
	
	return {
		["Location"] = string.match(tostring(getasyncinfo), [["timezone"%s*:%s*"([^"]+)"]]),
		["BuildVersion"] = formattedVersion,
		["Players"] = players,
	}
end

function MemoryService.Client:GetServersAttempt()
	return self.Server:GetServers()
end

function MemoryService:GetServers()
	local exclusiveLowerBound = nil
	local data = {}

	for _, serverType in Data.ServerTypes do
		-- this loop continues until the end of the map is reached
		data[serverType] = {}
		while true do
			-- get up to a hundred items starting from the current lower bound
			local items = serverMaps[self.serverType]:GetRangeAsync(Enum.SortDirection.Ascending, 100, exclusiveLowerBound)

			for _, item in ipairs(items) do
				data[serverType][item.key] = item.value
			end

			-- if the call returned less than a hundred items it means we've reached the end of the map
			if #items < 100 then
				break
			end

			-- the last retrieved key is the exclusive lower bound for the next iteration
			exclusiveLowerBound = {}
			exclusiveLowerBound["key"] = items[#items].key
			exclusiveLowerBound["sortKey"] = items[#items].sortKey
		end
	end
	
	return data
end

function MemoryService:SetServer()
	local success, err = pcall(function()
		serverMaps[self.serverType]:SetAsync(serverId, self:GetServerInfo(), 60 * 60 * 24)
	end)
	if not success then
		warn("Failed to set server data: " .. err)
	end
end

function MemoryService:RemoveServer()
	local success, err = pcall(function()
		serverMaps[self.serverType]:RemoveAsync(serverId)
	end)
	if not success then
		warn("Failed to remove server data: " .. err)
	end
end

function MemoryService:ManageServers()
	-- Players.PlayerAdded:Connect(function(player)
	-- 	local teleportData = player:GetJoinData()
	-- 	if teleportData and teleportData.ServerType then
	-- 		self.serverType = teleportData.ServerType
	-- 	end
	-- 	serverMaps[self.serverType] = serverMaps[self.serverType]
	-- end)
	for _, serverType in Data.ServerTypes do
		serverMaps[serverType] = MemoryStoreService:GetSortedMap("ServerInfo_" .. serverType)
	end
	
	task.spawn(function()
		game:BindToClose(function()
			self:RemoveServer()
		end)
		while true do
			self:SetServer()
			task.wait(60)
		end
	end)
	
	print("SERVER TYPE: ", self.serverType)
end

function MemoryService:KnitInit()
	self.serverType = Data.ServerTypes[1]
	self:ManageServers()
end

return MemoryService