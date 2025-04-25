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

local TicTacToe = {}
TicTacToe.__index = TicTacToe

function TicTacToe:CheckPrompt()
	if RunService:IsServer() then
		self.Prompt.Enabled = #self.Players < self.Data.MAX_PLAYERS
	elseif RunService:IsClient() then
		local joinGamePart: Part?
		local function check()
			local prompt = joinGamePart:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then
				prompt.Enabled = table.find(peek(self.Players), self.LocalPlayer.Name) == nil
			end
		end
		table.insert(self.Scope, Streamable.new(self.Model, "JoinGame"):Observe(function(streamedJoinGamePart: Part)
			joinGamePart = streamedJoinGamePart
			check()
		end))
		self.Scope:Observer(self.Players):onChange(check)
	end
end

function TicTacToe:AddPlayer(playerName: string)
	if RunService:IsServer() then
		if table.find(self.Players, playerName) then
			return
		end
		table.insert(self.Players, playerName)
		self.PlayerJoined:Fire(playerName)
		self:CheckPrompt()
		
		self.PlayerAddedPacket:Fire(self.Id, playerName)
		
		if #self.Players >= self.Data.PLAYERS_REQUIRED then
			self:StartGame()
		end
	elseif RunService:IsClient() then
		local newPlayers = peek(self.Players)
		table.insert(newPlayers, playerName)
		self.Players:set(newPlayers)
		
		self:CheckPrompt()
		
		if #peek(self.Players) >= self.Data.PLAYERS_REQUIRED then
			self:StartGame()
		end
	end
end

function TicTacToe:ManageJoining()
	if RunService:IsServer() then
		self.Trove:Add(self.Prompt.Triggered:Connect(function(playerTriggered: Player)
			self:AddPlayer(playerTriggered.Name)
		end))
	elseif RunService:IsClient() then
		table.insert(self.Scope, self.PlayerAddedPacket.OnClientEvent:Connect(function(id: string, playerName: string)
			if id ~= self.Id then
				return
			end
			self:AddPlayer(playerName)
		end))
	end
end

function TicTacToe:RemovePlayer(playerName: string)
	if RunService:IsServer() then
		local i = table.find(self.Players, playerName)
		if i then
			table.remove(self.Players, i)
			self:CheckPrompt()
			self.PlayerRemovedPacket:Fire(self.Id, playerName)
		end
		
		if #self.Players < self.Data.PLAYERS_REQUIRED then
			self:EndGame()
		end
	elseif RunService:IsClient() then
		local newPlayers = peek(self.Players)
		local i = table.find(newPlayers, playerName)
		if i then
			table.remove(newPlayers, i)
			self.Players:set(newPlayers)
			self:CheckPrompt()
		end
		
		if #peek(self.Players) < self.Data.PLAYERS_REQUIRED then
			self:EndGame()
		end
	end
end

function TicTacToe:ManageLeaving()
	if RunService:IsServer() then
		self.Trove:Add(self.PlayerJoined:Connect(function(playerName: string)
			task.spawn(function()
				while task.wait(1) do
					if not table.find(self.Players, playerName) then
						break
					end
					local char = playerName.Character
					if not char then
						continue
					end
					if (char:GetPivot().Position - self.Model:GetPivot().Position).Magnitude > self.Data.PLAYER_KICK_DISTANCE then
						self:RemovePlayer(playerName)
						break
					end
				end
			end)
		end))
		self.Trove:Add(Players.PlayerRemoving:Connect(function(player)
			self:RemovePlayer(player.Name)
		end))
	elseif RunService:IsClient() then
		table.insert(self.Scope, self.PlayerRemovedPacket.OnClientEvent:Connect(function(id: string, playerName: string)
			if id ~= self.Id then
				return
			end
			self:RemovePlayer(playerName)
		end))
	end
end

function TicTacToe:ManageSelecting()
	if RunService:IsServer() then
		self.SelectSlotPacket.OnServerInvoke = function(player: Player, id: string, column: number, slot: number)
			if id ~= self.Id then
				return
			end
			
			return true
		end
	elseif RunService:IsClient() then
		self.Scope:Observer(self.GameInProgress):onChange(function()
			if peek(self.GameInProgress) then
				print("GAME STARTED")
				for i=1, 3 do
					for j=1, 3 do
						table.insert(self.GameScope, Streamable.new(self.Model, "Board"):Observe(function(boardModel: Model, boardTrove: Trove.Trove)
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
			else
				print("GAME ENDED")
				self.GameScope:doCleanup()
			end
		end)
	end
end

function TicTacToe:StartGame()
	if RunService:IsServer() then
		self.GameInProgress = true
	elseif RunService:IsClient() then
		self.GameInProgress:set(true)
	end
	self.PlayerTurnIndex = self.Data.STARTER_PLAYER_INDEX
end

function TicTacToe:EndGame()
	if RunService:IsServer() then
		self.GameInProgress = false
	elseif RunService:IsClient() then
		self.GameInProgress:set(false)
	end
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
	
	self.PlayerTurnIndex = nil
	
	if RunService:IsServer() then
		self.Trove = Trove.new()
		
		self.GameInProgress = false
		
		self.PlayerJoined = self.Trove:Add(Signal.new())
		self.Players = {}
		
		self.Id = HttpService:GenerateGUID()
		Knit.Shared.Interactables[self.Id] = self
		self.Model:SetAttribute("Id", self.Id)
		
		self.Prompt = self.Model.JoinGame:FindFirstChild("Play") :: ProximityPrompt
	elseif RunService:IsClient() then
		self.Scope = Fusion:scoped()
		
		self.GameScope = Fusion:scoped()
		table.insert(self.Scope, self.GameScope)
		
		self.GameInProgress = self.Scope:Value(false)
		
		self.Players = self.Scope:Value({})
		self.LocalPlayer = Players.LocalPlayer
		
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
