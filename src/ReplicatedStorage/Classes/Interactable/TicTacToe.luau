local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local peek = Fusion.peek

local player = Players.LocalPlayer

local TicTacToe = {}
TicTacToe.__index = TicTacToe

function TicTacToe:CheckPrompt()
	if RunService:IsServer() then
		self.Prompt.Enabled = #self.Players < 2
	elseif RunService:IsClient() then
		local joinGamePart: Part?
		local function check()
			local prompt = joinGamePart:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then
				prompt.Enabled = table.find(peek(self.Players), player.Name) == nil
			end
		end
		table.insert(self.Scope, Streamable.new(self.Model, "JoinGame"):Observe(function(streamedJoinGamePart: Part)
			joinGamePart = streamedJoinGamePart
			check()
		end))
		self.Scope:Observer(self.Players):onChange(check)
	end
end

function TicTacToe:AddPlayer(player: Player)
	if table.find(self.Players, player) then
		return
	end
	table.insert(self.Players, player)
	self.PlayerJoined:Fire(player)
	self:CheckPrompt()
	
	self.PlayerAddedPacket:Fire(self.Id, player.Name)
end

function TicTacToe:ManageJoining()
	if RunService:IsServer() then
		self.Trove:Add(self.Prompt.Triggered:Connect(function(playerTriggered: Player)
			self:AddPlayer(playerTriggered)
		end))
	elseif RunService:IsClient() then
		table.insert(self.Scope, self.PlayerAddedPacket.OnClientEvent:Connect(function(id: string, player: string)
			if id ~= self.Id then
				return
			end
			
			local newPlayers = peek(self.Players)
			table.insert(newPlayers, player)
			self.Players:set(newPlayers)
			
			self:CheckPrompt()
		end))
	end
end

function TicTacToe:RemovePlayer(player: Player)
	local i = table.find(self.Players, player)
	if i then
		table.remove(self.Players, i)
		self:CheckPrompt()
		self.PlayerRemovedPacket:Fire(self.Id, player.Name)
	end
end

function TicTacToe:ManageLeaving()
	if RunService:IsServer() then
		self.Trove:Add(self.PlayerJoined:Connect(function(player: Player)
			task.spawn(function()
				while task.wait(1) do
					if not table.find(self.Players, player) then
						break
					end
					local char = player.Character
					if not char then
						continue
					end
					if (char:GetPivot().Position - self.Model:GetPivot().Position).Magnitude > self.Data.PLAYER_KICK_DISTANCE then
						self:RemovePlayer(player)
						break
					end
				end
			end)
		end))
		self.Trove:Add(Players.PlayerRemoving:Connect(function(player)
			self:RemovePlayer(player)
		end))
	elseif RunService:IsClient() then
		table.insert(self.Scope, self.PlayerRemovedPacket.OnClientEvent:Connect(function(id: string, player: string)
			if id ~= self.Id then
				return
			end
			
			local newPlayers = peek(self.Players)
			local i = table.find(newPlayers, player)
			if i then
				table.remove(newPlayers, i)
				self.Players:set(newPlayers)
				self:CheckPrompt()
			end
		end))
	end
end

function TicTacToe:ManageSelecting()
	if RunService:IsServer() then
		self.SelectSlotPacket.OnServerInvoke = function(playerSelected: Player, id: string, column: number, slot: number)
			if id ~= self.Id then
				return
			end
			
			return true
		end
	elseif RunService:IsClient() then
		for i=1, 3 do
			for j=1, 3 do
				table.insert(self.Scope, Streamable.new(self.Model, "Board"):Observe(function(boardModel: Model, boardTrove: Trove.Trove)
					boardTrove:Add(Streamable.new(boardModel, tostring(i)):Observe(function(columnModel: Model, columnTrove: Trove.Trove)
						columnTrove:Add(Streamable.new(columnModel, tostring(j)):Observe(function(slot: Part, slotTrove: Trove.Trove)
							slotTrove:Add(Streamable.new(slot, "ClickDetector"):Observe(function(cd: ClickDetector, detectorTrove: Trove.Trove)
								detectorTrove:Add(cd.MouseHoverEnter:Connect(function()
									self.SelectSlotPacket:Fire(self.Id, i, j, "TEST")
								end))
							end))
						end))
					end))
				end))
			end
		end
	end
end

function TicTacToe:StartGame()
	self.GameInProgress = true
	self.PlayerTurnIndex = self.Data.STARTER_PLAYER_INDEX
end

function TicTacToe:StopGame()
	self.GameInProgress = false
	self.PlayerTurnIndex = nil
end

function TicTacToe.new(model: Model)
	local self = setmetatable({}, TicTacToe)
	
	self.Model = model :: Model
	
	self.Data = Knit.Data.Interacting.TicTacToe
	
	local Packet = Knit.Utils.Packet
	self.PlayerAddedPacket = Packet("TTT_PlayerAdded", Packet.String, Packet.String)
	self.PlayerRemovedPacket = Packet("TTT_PlayerRemoved", Packet.String, Packet.String)
	self.SelectSlotPacket = Packet("TTT_SelectedSlot", Packet.String, Packet.NumberU8, Packet.NumberU8, Packet.String):Response(Packet.Boolean8)
	
	self.GameInProgress = false
	self.PlayerTurnIndex = nil
	
	if RunService:IsServer() then
		self.Trove = Trove.new()
		
		self.PlayerJoined = self.Trove:Add(Signal.new())
		self.Players = {}
		
		self.Id = HttpService:GenerateGUID()
		Knit.Shared.Interactables[self.Id] = self
		self.Model:SetAttribute("Id", self.Id)
		
		self.Prompt = self.Model.JoinGame:FindFirstChild("Play") :: ProximityPrompt
	elseif RunService:IsClient() then
		self.Scope = Fusion:scoped()
		
		self.Players = self.Scope:Value({})
		
		self.Id = self.Model:GetAttribute("Id")
		Knit.Shared.Interactables[self.Id] = self
	end
	self:ManageLeaving()
	self:ManageJoining()
	self:ManageSelecting()
	
	return self
end

function TicTacToe:Destroy()
	if RunService:IsServer() then
		self.Trove:Destroy()
	elseif RunService:IsClient() then
		self.Scope:doCleanup()
	end
end

return TicTacToe
