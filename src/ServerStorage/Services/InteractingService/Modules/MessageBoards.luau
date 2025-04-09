-- Services --
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local MessageBoardsData = require(ReplicatedStorage.Source.Data.Interacting.MessageBoards)

-- Main Module --
local MessageBoards = {
	Tag = "MessageBoard",
}

-- Local --
local service

local scope: Fusion.Scope

local messages: { [string]: {
	[Player]: {
		boardId: string,
		
		position: UDim2,
		size: UDim2,
		text: string
	}
} } = {}

local rnd = Random.new()

local boards: { [string]: Instance }  = {}

local function fireNewMessages(player: Player)
	service.Client.Interaction:Fire(player, "MessageBoards", "MessagesChanged", messages)
end

local function getFilterResult(text, fromUserId)
	local filterResult
	local success, errorMessage = pcall(function()
		filterResult = TextService:FilterStringAsync(text, fromUserId)
	end)

	if success then
		return filterResult
	else
		warn("Error generating TextFilterResult:", errorMessage)
	end
end

local function onInputReceived(player, text)
	if text ~= "" then
		local filterResult = getFilterResult(text, player.UserId)
		if filterResult then
			local success, filteredText = pcall(function()
				return filterResult:GetNonChatStringForBroadcastAsync()
			end)

			if not success then
				return ""
			end
			
			return filteredText
		end
	end
end

local function submitMessageAttempt(playerSent: Player, boardId: string, position: UDim2, size: UDim2, text: string)
	if not boardId or not position or not size or not text then
		return
	end
	if typeof(boardId) ~= "string" or typeof(position) ~= "UDim2" or typeof(size) ~= "UDim2" or typeof(text) ~= "string" then
		return
	end
	
	if not boards[boardId] then
		return
	end
	if not messages[boardId] then
		return
	end
	
	if string.len(text) <= 0 or string.len(text) >  MessageBoardsData.Gui.Message.MAX_CHARACTERS then
		return
	end
	text = onInputReceived(playerSent, text)
	
	messages[boardId][tostring(playerSent.UserId)] = {
		boardId = boardId,
		
		rotation = rnd:NextNumber(MessageBoardsData.Gui.Message.ROTATION_RANGE_MIN, MessageBoardsData.Gui.Message.ROTATION_RANGE_MAX),
		
		position = position,
		size = size,
		text = text
	}
	
	for _, player in Players:GetPlayers() do
		fireNewMessages(player)
	end
	
	return true
end

local function clearMessageAttempt(playerSent: Player, boardId: string)
	if not boardId or typeof(boardId) ~= "string"then
		return false
	end
	
	local userIdString = tostring(playerSent.UserId)
	
	local boardMessages = messages[boardId]
	if not boardMessages then
		return false
	end
	
	if not boardMessages[userIdString] then
		return false
	end
	
	boardMessages[userIdString] = nil
	
	for _, player in Players:GetPlayers() do
		fireNewMessages(player)
	end
	
	return true
end

MessageBoards.init = function()
	service = Knit.GetService("InteractingService")
end

MessageBoards.sentInteractAttempt = function(player: Player, interaction: string, ...)
	if interaction == "SubmitMessageAttempt" then
		return submitMessageAttempt(player, ...)
	elseif interaction == "ClearMessageAttempt" then
		return clearMessageAttempt(player, ...)
	end
end

MessageBoards.playerAdded = function(player: Player)
	fireNewMessages(player)
end

MessageBoards.playerRemoving = function(player: Player)
	for _, playerMessages in messages do
		playerMessages[tostring(player.UserId)] = nil
	end
	for _, otherPlayer in Players:GetPlayers() do
		fireNewMessages(otherPlayer)
	end
end

MessageBoards.taggedObjectAdded = function(taggedObject: Instance)
	local id = HttpService:GenerateGUID()
	taggedObject:SetAttribute("Id", id)
	boards[id] = taggedObject
	messages[id] = {}
end

MessageBoards.taggedObjectRemoved = function(taggedObject: Instance)
	local id = HttpService:GenerateGUID()
	messages[id] = nil
	boards[id] = nil
end

return MessageBoards