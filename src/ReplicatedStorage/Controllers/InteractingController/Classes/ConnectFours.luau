local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.ExPackages.Trove)
local Knit = require(ReplicatedStorage.ExPackages.Knit)
local Streamable = require(ReplicatedStorage.ExPackages.Streamable)

local InteractingController = Knit.GetController("InteractingController")
local MenuController = Knit.GetController("MenuController")

local ConnectFours = {}
ConnectFours.__index = ConnectFours

function ConnectFours.new(model: Model)
	local self = setmetatable({}, ConnectFours)
	
	self.Trove = Trove.new()
	
	local promptTrove = Trove.new()
	self.Trove:Add(promptTrove)
	self.PromptTrove = promptTrove
	
	local function updatePrompt()
		self.PromptTrove:Clean()
		self.PromptTrove:Add(Streamable.Streamable.new(model, "JoinGame"):Observe(function(joinGamePart: Part, trove: Trove.Trove)
			joinGamePart.Join.Enabled = table.find(self.CurrentPlayers, Players.LocalPlayer.Name) == nil
		end))
	end
	
	self.CurrentPlayers = {} :: { [number]: string }
	
	self.Trove:Add(InteractingController:ObserveInteraction("ConnectFours", function(interaction: string, modelId: string, ...)
		if modelId ~= model:GetAttribute("Id") then
			return
		end
		if interaction == "UpdatePlayers" then
			self.CurrentPlayers = {}
			
			local playerNames: { string }, playersReady: { string } = ...
			for i, v in playerNames do
				self.CurrentPlayers[i] = v
				if v == Players.LocalPlayer.Name then
					MenuController:SetMenu("ConnectFours")
				end
			end
			
			MenuController:SendToClass("ConnectFours", "NewPlayers", self.CurrentPlayers, playersReady)
			
			updatePrompt()
		elseif interaction == "Ready" then
			MenuController:SendToClass("ConnectFours", "Ready", ...)
		elseif interaction == "Kick" then
			local playerKickedName: string = ...
			table.remove(self.CurrentPlayers, table.find(self.CurrentPlayers, playerKickedName))
			MenuController:SendToClass("ConnectFours", "Kick", playerKickedName)
			
			updatePrompt()
		elseif interaction == "SetTurn" then
			MenuController:SendToClass("ConnectFours", "SetTurn", ...)
		elseif interaction == "ColumnSelected" then
			MenuController:SendToClass("ConnectFours", "ColumnSelected", ...)
		elseif interaction == "DroppedChip" then
			MenuController:SendToClass("ConnectFours", "DroppedChip", ...)
		elseif interaction == "Won" then
			MenuController:SendToClass("ConnectFours", "Won", ...)
			
			self.CurrentPlayers = {}
			updatePrompt()
		elseif interaction == "Tie" then
			MenuController:SendToClass("ConnectFours", "Tie", ...)
			
			self.CurrentPlayers = {}
			updatePrompt()
		end
	end))
	
	return self
end

function ConnectFours:Destroy()
	self.Trove:Destroy()
end

return ConnectFours
