local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local InteractingService = Knit.GetService("InteractingService")
local RunService = game:GetService("RunService")

local ConnectFours = {
	Data = require(ReplicatedStorage.Source.Data.Interacting.ConnectFours),
}
ConnectFours.__index = ConnectFours

function ConnectFours.new(model: Model)
	local self = setmetatable({}, ConnectFours)
	
	self.LocalTweenService = Knit.GetService("LocalTweenService")
	
	self.Id = HttpService:GenerateGUID()
	model:SetAttribute("Id", self.Id)
	
	self.Model = model
	self.Trove = Trove.new()
	self.GameTrove = Trove.new()
	
	self.CurrentPlayers = {} :: { [number]: string }
	self.ReadyPlayers = {} :: { [number]: string }
	self.TurnStarted = tick()
	
	self.GameInProgress = false
	self.TurnIndex = self.Data.START_PLAYER
	
	self.Board = {} :: { [number]: { [number]: string } }
	for i=1, self.Data.BOARD_COLUMNS do
		local column = {}
		for j=1, self.Data.BOARD_ROWS do
			column[j] = ""
		end
		self.Board[i] = column
	end
	
	self.ColumnAttachments = {} :: { [number]: Attachment }
	for _, attach: Attachment? in self.Model.Base:GetChildren() do
		if not attach:IsA("Attachment") then
			continue
		end
		self.ColumnAttachments[tonumber(string.sub(attach.Name, 5))] = attach
	end
	
	local joinProx: ProximityPrompt = model.JoinGame.Join
	
	local function updateBoardNames()
		for _, board: SurfaceGui in self.Model.BoardPart:GetChildren() do
			for i=1, 2 do
				local playerName = self.CurrentPlayers[i]
				board.Frame:FindFirstChild("Player" .. i).Text = playerName and Players:FindFirstChild(playerName).DisplayName or "Player " .. i
			end
		end
	end
	local function updatePrompt()
		joinProx.Enabled = #self.CurrentPlayers < 2
	end
	
	self.CountdownConnection = nil :: RBXScriptConnection?
	
	local function kickPlayer(playerName: string)
		for _, v in self.CurrentPlayers do
			local player: Player? = Players:FindFirstChild(v)
			if not player then
				continue
			end
			InteractingService.Client.Interaction:Fire(player, "ConnectFours", "Kick", self.Id, playerName)
		end
		
		table.remove(self.ReadyPlayers, table.find(self.ReadyPlayers, playerName))
		table.remove(self.CurrentPlayers, table.find(self.CurrentPlayers, playerName))
		
		if #self.CurrentPlayers == 0 then
			self:ResetGame()
			
			self.CurrentPlayers = {}
			self.ReadyPlayers = {}
		end
		
		updateBoardNames()
		updatePrompt()
	end
	local function kickCurrentPlayers()
		for i=#self.CurrentPlayers, 1, -1 do
			kickPlayer(self.CurrentPlayers[i])
		end
	end
	local function checkValidPlayer(playerName: string)
		return table.find(self.CurrentPlayers, playerName) ~= nil
	end
	local function playerLeaveAttempt(player: Player)
		if not checkValidPlayer(player.Name) then
			return
		end
		
		kickPlayer(player.Name)
		
		if self.GameInProgress then
			self.GameInProgress = false
			kickCurrentPlayers()
		end
	end
	local function playerJoined(player: Player)
		updateBoardNames()
		updatePrompt()
	end
	local function checkValidColumn(...)
		local columnIndex = ...
		assert(columnIndex and typeof(columnIndex) == "number", "Column index was nil or not of type number")
		assert(columnIndex >= 1 and columnIndex <= self.Data.BOARD_COLUMNS, "Column index was out of range")
	end
	
	self.Trove:Add(joinProx.Triggered:Connect(function(player: Player)
		if self.GameInProgress then
			return
		end
		if table.find(self.CurrentPlayers, player.Name) then
			return
		end
		table.insert(self.CurrentPlayers, player.Name)
		
		for _, v in self.CurrentPlayers do
			playerJoined(v)
			InteractingService.Client.Interaction:Fire(Players:FindFirstChild(v), "ConnectFours", "UpdatePlayers", self.Id, self.CurrentPlayers, self.ReadyPlayers)
		end
	end))
	self.Trove:Add(InteractingService:ObserveInteractAttempt("ConnectFours", function(player: Player, interaction: string, ...)
		local playerName = player.Name
		if interaction == "Ready" then
			if self.GameInProgress then
				return
			end
			if not table.find(self.CurrentPlayers, playerName) or table.find(self.ReadyPlayers, playerName) then
				return
			end
			table.insert(self.ReadyPlayers, playerName)
			
			for _, v in self.CurrentPlayers do
				InteractingService.Client.Interaction:Fire(Players:FindFirstChild(v), "ConnectFours", "Ready", self.Id, playerName)
			end
			
			if #self.CurrentPlayers < 2 then
				return
			end
			local allPlayersReady = true
			for _, v in self.CurrentPlayers do
				if not table.find(self.ReadyPlayers, v) then
					allPlayersReady = false
				end
			end
			if allPlayersReady then
				self:ResetCountdown()
				self.GameInProgress = true
			end
		elseif interaction == "Leave" then
			playerLeaveAttempt(player)
		elseif interaction == "SelectColumn" then
			if not checkValidPlayer(playerName) then
				return
			end
			if table.find(self.CurrentPlayers, playerName) ~= self.TurnIndex then
				return
			end
			checkValidColumn(...)
			for _, v in self.CurrentPlayers do
				if v == playerName then
					continue
				end
				InteractingService.Client.Interaction:Fire(Players:FindFirstChild(v), "ConnectFours", "ColumnSelected", self.Id, ...)
			end
		elseif interaction == "DropChip" then
			if not checkValidPlayer(playerName) then
				return
			end
			if table.find(self.CurrentPlayers, playerName) ~= self.TurnIndex then
				return
			end
			
			local column: number = ...
			checkValidColumn(column)
			
			local slotIndex: number? = self:DropChip(player, column)
			if slotIndex then
				for _, v in self.CurrentPlayers do
					InteractingService.Client.Interaction:Fire(Players:FindFirstChild(v), "ConnectFours", "DroppedChip", self.Id, playerName, column)
				end
				
				self:DropChipMeshAt(column, slotIndex, table.find(self.CurrentPlayers, playerName))
				
				if self:CheckWin(playerName) then
					for _, v in self.CurrentPlayers do
						InteractingService.Client.Interaction:Fire(Players:FindFirstChild(v), "ConnectFours", "Won", self.Id, playerName)
					end
					self:ResetGame()
				elseif self:CheckTie() then
					for _, v in self.CurrentPlayers do
						InteractingService.Client.Interaction:Fire(Players:FindFirstChild(v), "ConnectFours", "Tie", self.Id)
					end
					self:ResetGame()
				else
					print(1)
					self:NextTurn()
				end
			end
		end
	end))
	self.Trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		playerLeaveAttempt(player)
	end))
	
	-- for i=1, self.Data.BOARD_COLUMNS do
	-- 	for j=1, self.Data.BOARD_ROWS do
	-- 		self:DropChipMeshAt(i, j, 1)
	-- 	end
	-- end
	
	return self
end

function ConnectFours:GetMeshChipSlotPosition(slot: number)
	local chipSizeZ = ReplicatedStorage.Assets.Meshes.Chips.BlueChip.Size.Z
	return -((slot - 1) * (chipSizeZ + self.Data.BOARD_MODEL_ROW_MARGIN))
end

function ConnectFours:DropChipMeshAt(column: number, slot: number, chipIndex: number)
	local attach: Attachment = self.ColumnAttachments[column]
	
	local chip = self.GameTrove:Add(ReplicatedStorage.Assets.Meshes.Chips:FindFirstChild(self.Data.Chips[chipIndex]):Clone())
	chip.Parent = attach
	chip:PivotTo(attach.WorldCFrame * CFrame.new(self:GetMeshChipSlotPosition(0), 0, 0))
	
	self.LocalTweenService:Tween(chip, TweenInfo.new(1, Enum.EasingStyle.Bounce), { CFrame =  attach.WorldCFrame * CFrame.new(self:GetMeshChipSlotPosition(slot), 0, 0)})
end

function ConnectFours:NextTurn(timeout: boolean?)
	self.TurnIndex += 1
	if self.TurnIndex > 2 then
		self:ResetCountdown()
		self.TurnIndex = 1
	end
	for _, v in self.CurrentPlayers do
		InteractingService.Client.Interaction:Fire(Players:FindFirstChild(v), "ConnectFours", "SetTurn", self.Id, self.TurnIndex, timeout)
	end
end

function ConnectFours:ResetCountdown()
	self:DisconnectCountdown()
	
	self.TurnStarted = tick()
	self.CountdownConnection = RunService.Heartbeat:Connect(function()
		if tick() - self.TurnStarted > self.Data.TURN_TIME_OUT then
			self:NextTurn(true)
			self:ResetCountdown()
		end
	end)
end
function ConnectFours:DisconnectCountdown()
	if self.CountdownConnection then
		self.CountdownConnection:Disconnect()
		self.CountdownConnection = nil
	end
end

function ConnectFours:ResetGame()
	self.ReadyPlayers = {}
	
	self.GameInProgress = false
	self.TurnIndex = self.Data.START_PLAYER
	
	self:ResetCountdown()
	self:DisconnectCountdown()
	
	for _, slots in self.Board do
		for i, _ in slots do
			slots[i] = ""
		end
	end
	
	self.GameTrove:Destroy()
end

function ConnectFours:CheckWin(playerName: string)
	local cols = self.Data.BOARD_COLUMNS
    local rows = self.Data.BOARD_ROWS

    local function get(x, y)
        if x >= 1 and x <= cols and y >= 1 and y <= rows then
            return self.Board[x][y]
        end
        return nil
    end

    for x = 1, cols do
        for y = 1, rows do
            if get(x, y) == playerName then
                local directions = {
                    {1, 0},  -- horizontal →
                    {0, 1},  -- vertical ↓
                    {1, 1},  -- diagonal ↘
                    {1, -1}, -- diagonal ↗
                }

                for _, dir in ipairs(directions) do
                    local dx, dy = dir[1], dir[2]
                    local count = 1

                    for i = 1, 3 do
                        if get(x + i*dx, y + i*dy) == playerName then
                            count += 1
                        else
                            break
                        end
                    end

                    if count == 4 then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function ConnectFours:CheckTie()
	for col = 1, self.Data.BOARD_COLUMNS do
        for row = 1, self.Data.BOARD_ROWS do
            if self.Board[col][row] == "" then
                return false
            end
        end
    end
    return true
end

function ConnectFours:DropChip(player: Player, columnIndex: number)
	local column = self.Board[columnIndex]
    if not column then
		return false
	end

    for rowIndex = #column, 1, -1 do
        if column[rowIndex] == "" then
            column[rowIndex] = player.Name
            return rowIndex
        end
    end

    return false
end

function ConnectFours:Destroy()
	self.GameTrove:Destroy()
	self.Trove:Destroy()
end

return ConnectFours
