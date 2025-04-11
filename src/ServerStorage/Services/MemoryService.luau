-- Services --
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

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
local serversHashMap = MemoryStoreService:GetHashMap("Servers")

-- Constants --
local EXPIRATION = 600
local NUM_TEST_ITEMS = 32

function MemoryService:GetServerInfo()
	local url = "http://ip-api.com/json/"
	local getasyncinfo = HttpService:GetAsync(url) -- roblox server will get info from that link
	
	local players = {}
	for _, player: Player in Players:GetPlayers() do
		table.insert(players, player.UserId)
	end
	
	return {
		["Location"] = string.sub(tostring(getasyncinfo),31,37),
		["BuildVersion"] = game.PlaceVersion,
		["Players"] = players,
	}
end

function MemoryService:AddServer()
	task.spawn(function()
		local success, err = pcall(function()
			serversHashMap:SetAsync(game.JobId, self:GetServerInfo(), 1000)
		end)
		if not success then
			print("Error adding server: " .. err)
		else
			print("Server added successfully")
		end
	end)
end

function MemoryService:UpdateServer()
	local success, err = pcall(function()
		serversHashMap:UpdateAsync(game.JobId, function()
			return self:GetServerInfo()
		end, 1000)
	end)
	if not success then
		print("Error updating server: " .. err)
	else
		print("Server updated successfully")
	end
end

function MemoryService:RemoveServer()
	task.spawn(function()
		local success, err = pcall(function()
			serversHashMap:RemoveAsync(game.JobId)
		end)
		if not success then
			print("Error removing server: " .. err)
		else
			print("Server removed successfully")
		end
	end)
end

-- function MemoryService.Client:GetServersInfoAttempt(player: Player)
-- 	return self.Server:GetServersInfoAttempt(player)
-- end

function MemoryService:GetItemsFromAllPages(pages: MemoryStoreHashMapPages)
	-- Purely for logging purposes, we track what page number we're on
	local currentPageNumber = 1
	local retrievedItems = {}

	while not pages.IsFinished do
		print(`Getting items on page {currentPageNumber}...`)
		local items = pages:GetCurrentPage()

		for _, entry in pairs(items) do
			print(`\t{entry.key}: {entry.value}`)
			retrievedItems[entry.key] = entry.value
		end

		-- Advance pages if there are more pages to read
		if not pages.IsFinished then
			pages:AdvanceToNextPageAsync()
			currentPageNumber += 1
		end
	end
	
	print("Finished reading all pages")
	return retrievedItems
end

function MemoryService:GetServersInfoAttempt()
	return self:GetItemsFromAllPages(serversHashMap:ListItemsAsync(NUM_TEST_ITEMS))
end

function MemoryService:ManageServers()
	self:AddServer()
	game:BindToClose(function()
		self:RemoveServer()
	end)
	
	Players.PlayerAdded:Connect(function()
		self:UpdateServer()
	end)
	Players.PlayerRemoving:Connect(function()
		self:UpdateServer()
	end)
	
	task.delay(10, function()
		while task.wait(30) do
			for i, v in self:GetServersInfoAttempt() do
				print(i, v)
			end
		end
	end)
end

function MemoryService:KnitInit()
	self:ManageServers()
end

return MemoryService