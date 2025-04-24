-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Knit = require(Packages.Knit)

-- Service --
local DevelopingService = Knit.CreateService { Name = "DevelopingService" }

-- Types --
type Self = typeof(DevelopingService)

-- Local --
local player = Players.LocalPlayer

local Dev = {
	Developers = {
		1236498240; -- Mrloadd
	};
	CachedGui = {};
}

function DevelopingService:PlayerIsDeveloper(player: Player)
	return table.find(Dev.Developers, player.UserId)
end

function DevelopingService:ManageMessage(player: Player, message: string)
	local commands = require(script.Commands)
	
	-- Checking if the sent in message is a valid command
	local isCommand = commands.MessageIsACommand(message)
	if not isCommand then return end
	
	-- Attempting to trigger the command
	commands.TriggerCommandFromMessage(player, message)
end

function DevelopingService:KnitInit()
	-- Checking for a player to get added to the server
	Players.PlayerAdded:Connect(function(player)
		-- Checking if the player is a dev
		if not self:PlayerIsDeveloper(player) then return end
		
		-- Waiting for the player to send a chat message and then managing that message
		player.Chatted:Connect(function(message)
			self:ManageMessage(player, message)
			--script.Chatted:FireClient(player, message)
		end)
	end)
end

return DevelopingService