local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChipTemps: Folder = ReplicatedStorage:WaitForChild("Assets").Gui.Templates.Chips
local Sounds = ReplicatedStorage.Assets.Sounds.Interactables["Connect4's"]

local alarmSounds = Sounds.Alarm:GetChildren()

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local Sound = require(ReplicatedStorage.Source.Classes.Sound)

local InteractingController = Knit.GetController("InteractingController")
local InteractingService = Knit.GetService("InteractingService")
local MenuController = Knit.GetController("MenuController")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local ConnectFoursMenu = {
	Data = require(ReplicatedStorage.Source.Data.Interacting.ConnectFours),
}
ConnectFoursMenu.__index = ConnectFoursMenu

function ConnectFoursMenu.new(menu: ScreenGui)
	local self = setmetatable({}, ConnectFoursMenu)
	
	self.Scope = Fusion:scoped()
	self.Trove = Trove.new()
	
	self.GameScope = Fusion:scoped()
	table.insert(self.Scope, self.GameScope)
	
	local mainFrame: Frame = menu.Main
	local sideFrame: Frame = mainFrame.SideFrame
	
	self.ChipsFolder = mainFrame.Chips :: Folder
	
	-- Players --
	self.CurrentPlayers = self.Scope:Value({})
	self.ReadyPlayers = self.Scope:Value({})
	
	self.CountdownTime = self.Scope:Value(self.Data.TURN_TIME_OUT)
	self.CountdownConnection = nil :: RBXScriptConnection?
	
	self.GameInProgress = self.Scope:Value(false)
	self.TurnIndex = self.Scope:Value(nil)
	self.TurnStarted = tick()
	self.Winner = self.Scope:Value(nil)
	
	self.SelectedColumn = self.Scope:Value(self.Data.START_COLUMN)
	self.SelectChipPosition = self.Scope:Value(UDim2.new())
	self.ShowPlayAgainText = self.Scope:Value(false)
	
	local columnPadding = UDim.new(0.037, 0)
	local rowPadding = UDim.new(0.054, 0)
	local step = 0.0965
	
	self.Board = {} :: { [number]: { [number]: { Position: UDim2, Player: string } } }
	for i=1, self.Data.BOARD_COLUMNS do
		local column = {}
		for j=1, self.Data.BOARD_ROWS do
			column[j] = {
				Position = UDim2.fromScale((columnPadding.Scale * i) + (step * (i - 1)), (rowPadding.Scale * j) + (step * (j - 1))),
				Player = "",
			}
		end
		self.Board[i] = column
	end
	
	local chips = self.Data.Chips
	for i, v in chips do
		local chip: ImageLabel = ChipTemps:FindFirstChild(v):Clone()
		self.Scope:Hydrate(chip) {
			Parent = self.Scope:Computed(function(use: Fusion.Use)
				return use(self.TurnIndex) == i and self.ChipsFolder or nil
			end),
			Position = self.Scope:Spring(self.SelectChipPosition, 35, 0.5),
		}
	end
	
	self.SelectionSlots = {} :: { [number]: UDim2 }
	for i, slots in self.Board do
		self.SelectionSlots[i] = slots[1].Position - UDim2.fromScale(0, 0.1)
	end
	self.Scope:Observer(self.SelectedColumn):onBind(function()
		self.SelectChipPosition:set(self.SelectionSlots[peek(self.SelectedColumn)])
	end)
	
	local playerFramesData = {}
	local function hydratePlayerFrames()
		for i, v in playerFramesData do
			local playerFrame = v.Frame
			self.Scope:Hydrate(playerFrame.Info.Status) {
				Text = self.Scope:Computed(function(use: Fusion.Use)
					return use(v.Player) and `Player {i}` or "Waiting for player..."
				end)
			}
			self.Scope:Hydrate(playerFrame.Info.Username) {
				Text = self.Scope:Computed(function(use: Fusion.Use)
					local playerName: string? = use(v.Player)
					return playerName and playerName or "..."
				end)
			}
			self.Scope:Hydrate(playerFrame.Icon.Playing) {
				Size = self.Scope:Spring(self.Scope:Computed(function(use: Fusion.Use)
					local playerName = use(v.Player)
					return if playerName and use(self.CurrentPlayers)[use(self.TurnIndex)] == playerName then UDim2.fromScale(0.6, 0.6) else UDim2.new()
				end), 25, 0.8),
			}
		end
	end
	for _, playerFrame in sideFrame.Players:GetChildren() do
		if not playerFrame:IsA("Frame") then
			continue
		end
		local index = tonumber(string.sub(playerFrame.Name, 7))
		if not index then
			continue
		end
		playerFramesData[index] = {
			Frame = playerFrame,
			Player = self.Scope:Value(nil),
			Ready = self.Scope:Value(false),
		}
	end
	hydratePlayerFrames()
	
	self.Scope:Computed(function(use: Fusion.Use)
		local currentPlayers = peek(self.CurrentPlayers)

		for i, v in playerFramesData do
			local playerName = currentPlayers[i]
			v.Player:set(playerName)
			v.Ready:set(use(self.ReadyPlayers)[use(v.Player)])
		end
		
		if table.find(currentPlayers, player.Name) == use(self.TurnIndex) and use(self.GameInProgress) then
			local lastSlotIndex = nil
			self.Trove:Add(mouse.Move:Connect(function()
				local relativeX = (mouse.X - mainFrame.AbsolutePosition.X) / mainFrame.AbsoluteSize.X
				
				local closestIndex = 1
				local closestDist = math.huge

				for i, pos in self.SelectionSlots do
					local dist = math.abs(pos.X.Scale - relativeX)
					if dist + self.Data.SELECT_COLUMN_MARGIN < closestDist then
						closestDist = dist
						closestIndex = i
					end
				end
				
				if closestIndex ~= lastSlotIndex then
					self.SelectedColumn:set(closestIndex)
					lastSlotIndex = closestIndex
					InteractingService:InteractAttempt("ConnectFours", "SelectColumn", closestIndex)
				end
			end))
			self.Trove:Add(UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
				if gameProcessedEvent then
					return
				end
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					InteractingService:InteractAttempt("ConnectFours", "DropChip", use(self.SelectedColumn))
				end
			end))
		else
			self.Trove:Clean()
		end
	end)
	
	self.Scope:Hydrate(sideFrame:FindFirstChild("Ready/PlayAgain")) {
		Visible = self.Scope:Computed(function(use: Fusion.Use)
			local allPlayersIn = #use(self.CurrentPlayers) == #playerFramesData
			local isReady = use(self.ReadyPlayers)[Players.LocalPlayer.Name] ~= nil
			return allPlayersIn and not isReady
		end),
		Text = self.Scope:Computed(function(use: Fusion.Use)
			return use(self.ShowPlayAgainText) and "Play Again?" or "Ready"
		end),
		[OnEvent("MouseButton1Down")] = function()
			InteractingService:InteractAttempt("ConnectFours", "Ready")
		end,
	}
	
	local winnerCanvas: CanvasGroup = mainFrame.WinnerCanvas
	local winnerCanvasStartSize = winnerCanvas.Size
	local winnerCanvasStartPos = winnerCanvas.Position
	self.Scope:Hydrate(winnerCanvas) {
		Position = self.Scope:Spring(self.Scope:Computed(function(use: Fusion.Use)
			return use(self.Winner) and winnerCanvasStartPos or winnerCanvasStartPos + UDim2.fromScale(0, 0.3)
		end), 15, 0.6),
		Size = self.Scope:Spring(self.Scope:Computed(function(use: Fusion.Use)
			return use(self.Winner) and winnerCanvasStartSize or UDim2.new()
		end), 15, 0.6),
		GroupTransparency = self.Scope:Tween(self.Scope:Computed(function(use: Fusion.Use)
			return use(self.Winner) and 0 or 1
		end), TweenInfo.new(0.25)),
	}
	self.Scope:Observer(self.Winner):onChange(function()
		local winner = peek(self.Winner)
		local isTie = winner == "Tie"
		local winnerText = isTie and "No more room..." or `@{winner}`
		winnerCanvas:FindFirstChild("Username").Text = winnerText
		winnerCanvas:FindFirstChild("GameFinishStatus").Text = isTie and "Tie!" or "WINNER!"
	end)
	
	self.Scope:Observer(self.GameInProgress):onBind(function()
		local gameInProgress = peek(self.GameInProgress)
		sideFrame.GameStatus.Text = gameInProgress and "Game in progress..." or "Match making in progress..."
		
		if peek(self.GameInProgress) then
			task.delay(self.Data.TURN_COOLDOWN, function()
				self:StartTurnCountdown()
				self.TurnIndex:set(self.Data.START_PLAYER)
			end)
		end
	end)
	
	local countdown: ImageLabel = sideFrame.Countdown
	self.Scope:Observer(self.TurnIndex):onBind(function()
		countdown.Visible = peek(self.TurnIndex) ~= nil
	end)
	self.Scope:Observer(self.CountdownTime):onBind(function()
		countdown.Time.Text = peek(self.CountdownTime)
	end)
	
	table.insert(self.Scope, mainFrame.Lower.Exit.MouseButton1Click:Connect(function()
		InteractingService:InteractAttempt("ConnectFours", "Leave")
	end))
	
	return self
end

function ConnectFoursMenu:StartGame()
	self.GameInProgress:set(true)
	
	self:DisconnectCountdown()
	self:ResetCountdown()
end

function ConnectFoursMenu:StartTurnCountdown()
	self:DisconnectCountdown()
	self:ResetCountdown()
	
	local lastTick = tick()
	self.CountdownConnection = RunService.Heartbeat:Connect(function()
		self.CountdownTime:set(self.Data.TURN_TIME_OUT - math.clamp(math.floor(tick() - self.TurnStarted), 0, self.Data.TURN_TIME_OUT))
		if tick() - lastTick > 1 then
			lastTick = tick()
			Sound.new(Sounds.Ticking):Play()
		end
	end)
end

function ConnectFoursMenu:DisconnectCountdown()
	if self.CountdownConnection then
		self.CountdownConnection:Disconnect()
		self.CountdownConnection = nil
	end
end

function ConnectFoursMenu:ResetCountdown()
	self.CountdownTime:set(self.Data.TURN_TIME_OUT)
	self.TurnStarted = tick()
end

function ConnectFoursMenu:ResetGame()
	self.GameInProgress:set(false)
	
	self.ReadyPlayers:set({})
	
	self.TurnIndex:set(nil)
	self.Winner:set(nil)
	
	self.SelectedColumn:set(self.Data.START_COLUMN)
	
	self:DisconnectCountdown()
	self:ResetCountdown()
	
	for column, slots in self.Board do
		for _, slot in slots do
			slot.Player = ""
		end
	end
	
	self.GameScope:doCleanup()
end

function ConnectFoursMenu:PlayAgain()
	task.delay(3, function()
		if table.find(peek(self.CurrentPlayers), player.Name) then
			self.ShowPlayAgainText:set(true)
		end
		self:ResetGame()
	end)
end

function ConnectFoursMenu:RecieveData(dataType: string, ...)
	if dataType == "NewPlayers" then
		local newPlayers, readyPlayers = ...
		self.CurrentPlayers:set(newPlayers)
		self.ReadyPlayers:set(readyPlayers)
		
		self:ResetCountdown()
	elseif dataType == "Ready" then
		local newReadyPlayers = peek(self.ReadyPlayers)
		newReadyPlayers[...] = true
		self.ReadyPlayers:set(newReadyPlayers)
		
		local currentPlayers = peek(self.CurrentPlayers)
		local allPlayersReady = true
		for _, v in currentPlayers do
			if not peek(self.ReadyPlayers)[v] then
				allPlayersReady = false
			end
		end
		if #currentPlayers < 2 then
			allPlayersReady = false
		end
		if allPlayersReady then
			self:StartGame()
		end
	elseif dataType == "Kick" then
		local currentPlayers = peek(self.CurrentPlayers)
		
		local playerName = ...
		if playerName == player.Name then
			currentPlayers = {}
			MenuController:CloseMenu("ConnectFours")
			self.ShowPlayAgainText:set(false)
		else
			for i, v in currentPlayers do
				if v == playerName then
					table.remove(currentPlayers, i)
					break
				end
			end
		end
		
		self.CurrentPlayers:set(currentPlayers)
		self.ReadyPlayers:set({})
		
		if #peek(self.CurrentPlayers) == 0 then
			self.ReadyPlayers:set({})
			self:ResetGame()
		end
	elseif dataType == "SetTurn" then
		local turnIndex, timeout = ...
		if timeout then
			Sound.new(alarmSounds[math.random(1, #alarmSounds)]):Play()
		end
		self:StartTurnCountdown()
		self.TurnIndex:set(turnIndex)
	elseif dataType == "ColumnSelected" then
		self.SelectedColumn:set(...)
	elseif dataType == "DroppedChip" then
		local playerName, columnIndex = ...
		
		local targetPos: UDim2
		local lastSlot
		for _, slot in self.Board[columnIndex] do
			if slot.Player == "" then
				lastSlot = slot
				targetPos = slot.Position
			end
		end
		lastSlot.Player = playerName
		
		local pos = self.GameScope:Value(self.SelectionSlots[columnIndex])
		self.GameScope:Hydrate(ChipTemps:FindFirstChild(self.Data.Chips[table.find(peek(self.CurrentPlayers), playerName)]):Clone()) {
			Parent = self.ChipsFolder,
			Position = self.GameScope:Tween(pos, TweenInfo.new(1, Enum.EasingStyle.Bounce)),
		}
		pos:set(targetPos)
	elseif dataType == "Won" then
		self.Winner:set(...)
		self:PlayAgain()
	elseif dataType == "Tie" then
		self.Winner:set("Tie")
		self:PlayAgain()
	end
end

function ConnectFoursMenu:Destroy()
	self.Scope:doCleanup()
	self.Trove:Destroy()
end

return ConnectFoursMenu