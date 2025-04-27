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

export type self = typeof(TicTacToe)

function TicTacToe:ManagePrompt()
	if self.IsServer then
		local function check()
			self.Prompt.Enabled = #self.Players < self.Data.MAX_PLAYERS
		end
		self.Trove:Add(self.PlayerJoined:Connect(check))
		self.Trove:Add(self.PlayerRemoving:Connect(check))
		self.Trove:Add(self.GameEnded:Connect(check))
		
		self.Trove:Add(self.Prompt.Triggered:Connect(function(playerTriggered: Player)
			if #self.Players == self.Data.MAX_PLAYERS then
				return
			end
			self:AddPlayer(playerTriggered.Name)
		end))
	elseif self.IsClient then
		local joinGamePart: Part?
		local function check()
			local prompt = joinGamePart:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then
				local players = peek(self.Players)
				prompt.Enabled = table.find(players, self.LocalPlayer.Name) == nil and #players < self.Data.MAX_PLAYERS
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
	if self.IsServer then
		if table.find(self.Players, playerName) then
			return
		end
		table.insert(self.Players, playerName)
		self.PlayerJoined:Fire(playerName)
		
		self.PlayerAddedPacket:Fire(self.Id, playerName)
		
		if #self.Players >= self.Data.PLAYERS_REQUIRED then
			self:StartGame()
		end
	elseif self.IsClient then
		local newPlayers = peek(self.Players)
		table.insert(newPlayers, playerName)
		self.Players:set(newPlayers)
		
		if #peek(self.Players) >= self.Data.PLAYERS_REQUIRED then
			self:StartGame()
		end
	end
end

function TicTacToe:ManageJoining()
	table.insert(self.Scope, self.PlayerAddedPacket.OnClientEvent:Connect(function(id: string, playerName: string)
		if id ~= self.Id then
			return
		end
		self:AddPlayer(playerName)
	end))
end

function TicTacToe:RemovePlayer(playerName: string)
	if self.IsServer then
		local i = table.find(self.Players, playerName)
		if i then
			table.remove(self.Players, i)
			
			self.PlayerRemovingPacket:Fire(self.Id, playerName)
			self.PlayerRemoving:Fire(playerName)
			
			if #self.Players < self.Data.PLAYERS_REQUIRED then
				self:EndGame()
			end
		end
	elseif self.IsClient then
		local newPlayers = peek(self.Players)
		local i = table.find(newPlayers, playerName)
		if i then
			table.remove(newPlayers, i)
			self.Players:set(newPlayers)
			
			if #peek(self.Players) < self.Data.PLAYERS_REQUIRED then
				self:EndGame()
			end
		end
	end
end

function TicTacToe:ManageLeaving()
	if self.IsServer then
		self.Trove:Add(self.PlayerJoined:Connect(function(playerName: string)
			task.spawn(function()
				while task.wait(1) do
					if not table.find(self.Players, playerName) then
						break
					end
					local char = Players:FindFirstChild(playerName).Character
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
	elseif self.IsClient then
		table.insert(self.Trove, self.PlayerRemovingPacket.OnClientEvent:Connect(function(id: string, playerName: string)
			if id ~= self.Id then
				return
			end
			self:RemovePlayer(playerName)
		end))
	end
end

function TicTacToe:GetModelSlotPosition(column: number, slot: number)
	return self.Model.Board:FindFirstChild(column):FindFirstChild(slot).Position
end

function TicTacToe:SelectSlot(symbol: BasePart, column: number, slot: number)
	self:Unselect()
	
	local hoverHeight = Vector3.yAxis * self.Data.SYMBOL_HOVER_HEIGHT
	local startPos = self:GetModelSlotPosition(column, slot) + hoverHeight
	
	local newSymbol = symbol:Clone()
	newSymbol.Position = startPos
	newSymbol.Transparency = 0.8
	newSymbol.Parent = self.Model:FindFirstChild("JoinGame")
	self.LocalTweenService:Tween(newSymbol, self.Data.SYMBOL_TWEEN_INFO, {
		Position = startPos - hoverHeight / 2,
		Transparency = 0.3,
	})
	
	self.SelectingSymbol = newSymbol
end

function TicTacToe:Unselect()
	local lastSymbol = self.SelectingSymbol
	if lastSymbol then
		lastSymbol:Destroy()
		self.LocalTweenService:CancelTween(lastSymbol)
	end
end

function TicTacToe:CheckValidColumnAndSlot(column: number, slot: number)
	return(column >= 1 and column <= self.Data.COLUMNS) and (slot >= 1 or slot <= self.Data.ROWS)
end

function TicTacToe:CheckValidTurn(playerName: string)
	return self.PlayerTurnIndex ~= nil and self.PlayerTurnIndex == table.find(self.Players, playerName)
end

function TicTacToe:GetSlotPart(column: number, slot: number)
	return self.Model:FindFirstChild("Board"):FindFirstChild(tostring(column)):FindFirstChild(tostring(slot))
end

function TicTacToe:ManageSlotInteractions()
	if self.IsServer then
		for i=1, self.Data.COLUMNS do
			for j=1, self.Data.ROWS do
				local cd: ClickDetector = self:GetSlotPart(i, j):FindFirstChildWhichIsA("ClickDetector")
				self.Trove:Add(cd.MouseHoverEnter:Connect(function(player: Player)
					if not self:CheckValidTurn(player.Name) then
						return
					end
					self:SelectSlot(self:GetSymbolFromIndex(self.PlayerTurnIndex), i, j)
				end))
				self.Trove:Add(cd.MouseHoverLeave:Connect(function(player: Player)
					if not self:CheckValidTurn(player.Name) then
						return
					end
					self:Unselect()
				end))
				self.Trove:Add(cd.MouseClick:Connect(function(player: Player)
					if not self:CheckValidTurn(player.Name) then
						return
					end
					local endedGame = self:PlaceSymbolAtSlot(table.find(self.Players, player.Name), i, j)
					if not endedGame then
						self:ProgressTurn()
					end
				end))
			end
		end
	elseif self.IsClient then
		local function checkSlotClickDetector(column: number, slot: number, cd: ClickDetector)
			local playerIndex = table.find(peek(self.Players), self.LocalPlayer.Name)
			cd.MaxActivationDistance = if self:CheckSlotOccupied(column, slot) or
									not playerIndex or
									self.PlayerTurnIndex ~= playerIndex or
									not peek(self.GameInProgress) then 0 else self.Data.SLOT_CLICK_DETECTOR_ACTIVATION_DISTANCE
		end
		self.Scope:Observer(self.GameInProgress):onBind(function()
			self.GameScope:doCleanup()
			self.GameTrove:Clean()
			
			for i=1, self.Data.COLUMNS do
				for j=1, self.Data.ROWS do
					self.GameTrove:Add(Streamable.new(self.Model, "Board"):Observe(function(boardModel: Model, boardTrove: Trove.Trove)
						boardTrove:Add(Streamable.new(boardModel, tostring(i)):Observe(function(columnModel: Model, columnTrove: Trove.Trove)
							columnTrove:Add(Streamable.new(columnModel, tostring(j)):Observe(function(slotPart: Part, slotTrove: Trove.Trove)
								slotTrove:Add(Streamable.new(slotPart, "ClickDetector"):Observe(function(cd: ClickDetector, detectorTrove: Trove.Trove)
									local column, slot = tonumber(columnModel.Name), tonumber(slotPart.Name)
									detectorTrove:Add(self.TurnProgressed:Connect(function()
										checkSlotClickDetector(column, slot, cd)
									end))
									checkSlotClickDetector(column, slot, cd)
								end))
							end))
						end))
					end))
				end
			end
		end)
	end
end

function TicTacToe:ManagePlacing()
	self.Trove:Add(self.PlaceSymbolPacket.OnClientEvent:Connect(function(id: number, playerName: string, column: number, slot: number, endGame: boolean)
		if id ~= self.Id then
			return
		end
		
		local newBoard = peek(self.Board)
		newBoard[column][slot] = table.find(peek(self.Players), playerName)
		self.Board:set(newBoard)
		if endGame then
			self:EndGame()
		else
			self:ProgressTurn()
		end
	end))
end

function TicTacToe:GetSymbolFromIndex(index: number)
	return ReplicatedStorage.Assets.Meshes.TicTacToe:FindFirstChild(self.Data.PLAYER_SYMBOLS[index])
end

function TicTacToe:PlaceSymbolAtSlot(symbolIndex: number, column: number, slot: number)
	if not self:CheckValidColumnAndSlot(column, slot) then
		return false
	end
	if self:CheckSlotOccupied(column, slot) then
		return
	end
	local playerName = self.Players[symbolIndex]
	self.Board[column][slot] = playerName
	
	local symbol: BasePart = self.GameTrove:Add(self:GetSymbolFromIndex(symbolIndex):Clone())
	symbol.Position = self:GetModelSlotPosition(column, slot)
	symbol.Parent = self:GetSlotPart(column, slot)
	
	local endGame = false
	local won, slots = self:CheckWin(playerName)
	if won then
		local function getSlotFromCoordinate(coordinate: {x: number, y: number})
			return self.Model.Board:FindFirstChild(tostring(coordinate.y)):FindFirstChild(tostring(coordinate.x))
		end
		local symbolA: Part, symbolB: Part = getSlotFromCoordinate(slots[1]), getSlotFromCoordinate(slots[3])
		
		local A = symbolA:GetPivot().Position
		local B = symbolB:GetPivot().Position

		local midpoint = (A + B) / 2
		local distance = (B - A).Magnitude

		local part = self.GameTrove:Add(Instance.new("Part"))
		part.Name = "Line"
		part.Size = Vector3.new(0.2, distance, 0.2)
		for key, value in self.Data.LINE_PART_PROPERTIES do
			part[key] = value
		end
		part.CFrame = CFrame.lookAt(midpoint, B) * CFrame.Angles(math.rad(90), 0, 0)
		part.Parent = self.Model
		
		endGame = true
	elseif self:CheckTie() then
		endGame = true
	end
	
	if endGame then
		self:EndGame()
	end
	
	self.PlaceSymbolPacket:Fire(self.Id, playerName, column, slot, endGame)
	
	return endGame
end

function TicTacToe:StartGame()
	self.PlayerTurnIndex = self.Data.STARTER_PLAYER_INDEX
	if self.IsServer then
		self.GameInProgress = true
	elseif self.IsClient then
		self.GameInProgress:set(true)
	end
end

function TicTacToe:GenerateBoard()
	local board = {}
	for i=1, self.Data.COLUMNS do
		local column = {}
		for j=1, self.Data.ROWS do
			column[j] = ""
		end
		board[i] = column
	end
	return board
end

function TicTacToe:EndGame()
	if self.IsServer then
		self.GameInProgress = false
	elseif self.IsClient then
		self.GameInProgress:set(false)
	end
	task.delay(self.Data.GAME_COOLDOWN, function()
		if self.IsServer then
			self.Players = {}
			self.Board = self:GenerateBoard()
			self.GameEnded:Fire()
		elseif self.IsClient then
			self.Board:set(self:GenerateBoard())
			self.Players:set({})
		end
		self.GameTrove:Clean()
		self.PlayerTurnIndex = nil
	end)
end

function TicTacToe:ProgressTurn()
	local selectingSymbol = self.SelectingSymbol
	if selectingSymbol then
		self.LocalTweenService:CancelTween(selectingSymbol)
		selectingSymbol:Destroy()
	end
	
	self.PlayerTurnIndex += 1
	if self.PlayerTurnIndex > (if self.IsServer then #self.Players else #peek(self.Players)) then
		self.PlayerTurnIndex = 1
	end
	
	if self.IsClient then
		self.TurnProgressed:Fire()
	end
end

function TicTacToe:CheckSlotOccupied(column: number, slot: number)
	if self.IsServer then
		return self.Board[column][slot] ~= ""
	elseif self.IsClient then
		return peek(self.Board)[column][slot] ~= ""
	end
end

function TicTacToe:CheckWin(playerName: string)
	return Knit.Utils.Calculations.FindRowSequence(self.Board, self.Data.COLUMNS, self.Data.ROWS, playerName, 3)
end

function TicTacToe:CheckTie()
	for x = 1, self.Data.COLUMNS do
		for y = 1, self.Data.ROWS do
			if self.Board[x][y] == "" then
				return false -- Found empty slot
			end
		end
	end
	return true
end

function TicTacToe.new(model: Model)
	local self = setmetatable({}, TicTacToe)
	
	self.IsServer, self.IsClient = RunService:IsServer(), RunService:IsClient()
	
	self.LocalTweenService = Knit.GetService("LocalTweenService")
	
	self.Model = model :: Model
	
	self.Data = Knit.Data.Interacting.TicTacToe
	
	local Packet = Knit.Utils.Packet
	self.PlayerAddedPacket = Packet("TTT_PlayerAdded", Packet.String, Packet.String)
	self.PlayerRemovingPacket = Packet("TTT_PlayerRemoving", Packet.String, Packet.String)
	self.SelectSlotPacket = Packet("TTT_SelectedSlot", Packet.String, Packet.NumberU8, Packet.NumberU8)
	self.PlaceSymbolPacket = Packet("TTT_PlaceSymbol", Packet.String, Packet.String, Packet.NumberU8, Packet.NumberU8, Packet.Boolean8)
	
	self.PlayerTurnIndex = nil
	
	if self.IsServer then
		self.Trove = Trove.new()
		self.GameTrove = self.Trove:Add(Trove.new()) :: Trove.Trove
		
		self.GameInProgress = false
		self.Board = self:GenerateBoard()
		
		self.PlayerJoined = self.Trove:Add(Signal.new())
		self.PlayerRemoving = self.Trove:Add(Signal.new())
		self.GameEnded = self.Trove:Add(Signal.new())
		self.Players = {}
		
		self.Id = HttpService:GenerateGUID()
		Knit.Shared.Interactables[self.Id] = self
		self.Model:SetAttribute("Id", self.Id)
		
		self.Prompt = self.Model.JoinGame:FindFirstChild("Play") :: ProximityPrompt
	elseif self.IsClient then
		self.Scope = Fusion:scoped()
		
		self.Trove = Trove.new()
		table.insert(self.Scope, self.Trove)
		
		self.GameScope = Fusion:scoped()
		table.insert(self.Scope, self.GameScope)
		
		self.GameTrove = Trove.new()
		table.insert(self.Scope, self.GameTrove)
		
		self.TurnProgressed = self.Trove:Add(Signal.new())
		
		self.GameInProgress = self.Scope:Value(false)
		self.Board = self.Scope:Value(self:GenerateBoard())
		
		self.Players = self.Scope:Value({})
		self.LocalPlayer = Players.LocalPlayer
		
		self.Id = self.Model:GetAttribute("Id")
		Knit.Shared.Interactables[self.Id] = self
		
		self:ManageJoining()
		self:ManagePlacing()
	end
	self:ManagePrompt()
	self:ManageLeaving()
	self:ManageSlotInteractions()
	
	return self
end

function TicTacToe:Destroy()
	if self.IsServer then
		self.Trove:Destroy()
	elseif self.IsClient then
		self.Scope:doCleanup()
	end
end

return TicTacToe
