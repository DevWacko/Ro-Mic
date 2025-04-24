-- Services --
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Packages --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Knit = require(Packages.Knit)

local BoothsData = require(ReplicatedStorage.Source.Data.Interacting.Booths)

local filterString = require(ServerStorage.Source.Utils.filterString)

-- Main Module --
local Booths = {
	Tag = "Booth",
}

-- Local --
local playerDataService
local service

local serverBoothsData: { [string]: {
	-- scope: Fusion.scope,
	ownerUserId: string?,
	textData: {
		text: string,
		textColor: Color3, strokeColor: Color3,
		font: Font, strokeThickness: number,
	},
} } = {}

local playerBooths: { [string]: Model } = {}
local boothModels: { [string]: Model } = {}

local function dataFromBooth(booth: Model)
	return serverBoothsData[booth:GetAttribute("Id")]
end

local function updateBoothsForPlayer(player: Player)
	service.Client.Interaction:Fire(player, "Booths", "UpdateBoothsData", serverBoothsData)
end

local function claimAttempt(player: Player, booth: Model)
	local userIdString = tostring(player.UserId)
	
	local data = dataFromBooth(booth)
	if not data then
		return
	end
	if playerBooths[userIdString] then
		return
	end
	
	local ownerUserId = data.ownerUserId
	if ownerUserId then
		return
	end
	data.ownerUserId = userIdString
	data.textData = BoothsData.Defaults.DESCRIPTION_DATA
	
	playerBooths[userIdString] = booth
	
	for _, otherPlayer in Players:GetPlayers() do
		updateBoothsForPlayer(otherPlayer)
	end
end

local function editAttempt(player: Player, booth: Model)
	local data = dataFromBooth(booth)
	if not data then
		return
	end
	
	local ownerUserId = data.ownerUserId
	if ownerUserId ~= tostring(player.UserId) then
		return
	end
	
	return true
end

local function unclaimAttempt(player: Player)
	local userIdString = tostring(player.UserId)
	
	if not playerBooths[userIdString] then
		return false
	end
	
	for _, boothData in serverBoothsData do
		if boothData.ownerUserId ~= userIdString then
			continue
		end
		boothData.ownerUserId = nil
		
		playerBooths[userIdString] = nil
	end
	
	for _, otherPlayer in Players:GetPlayers() do
		updateBoothsForPlayer(otherPlayer)
	end
	
	return true
end

local function setTextAttempt(
	player: Player,
	text: string,
	textColorIndex: number, strokeColorIndex: number,
	fontIndex: number, weightIndex: number, styleIndex: number,
	strokeOpacity: number
)
	if not text or
		not textColorIndex or not strokeColorIndex or
		not fontIndex or not weightIndex or not styleIndex or
		not strokeOpacity then
		return
	end
	if typeof(text) ~= "string" or
		typeof(textColorIndex) ~= "number" or typeof(strokeColorIndex) ~= "number" or
		typeof(fontIndex) ~= "number" or typeof(weightIndex) ~= "number" or typeof(styleIndex) ~= "number" or
		typeof(strokeOpacity) ~= "number" then
		return
	end
	
	local userIdString = tostring(player.UserId)
	
	local playerBooth = playerBooths[userIdString]
	if not playerBooth then
		return
	end
	
	local playerBoothData = serverBoothsData[playerBooth:GetAttribute("Id")]
	if not playerBoothData then
		return
	end
	
	playerDataService:SetValue(player, "BoothTextData", {
		TextColorIndex = textColorIndex, StrokeColorIndex = strokeColorIndex,
		FontIndex = fontIndex, WeightIndex = weightIndex, StyleIndex = styleIndex,
		StrokeOpacity = strokeOpacity,
	})
	local boothStylingData = BoothsData.BoothStyling
	playerBoothData.textData = {
		text = filterString(player, text),
		textColor = boothStylingData.COLORS[textColorIndex], strokeColor = boothStylingData.COLORS[strokeColorIndex],
		font = boothStylingData.FONTS[fontIndex], weight = boothStylingData.WEIGHTS[weightIndex], style = boothStylingData.STYLES[styleIndex],
		strokeOpacity = strokeOpacity,
	}
	
	for _, otherPlayer in Players:GetPlayers() do
		updateBoothsForPlayer(otherPlayer)
	end
end

Booths.sentInteractAttempt = function(player: Player, interaction: string, ...)
	if not interaction or typeof(interaction) ~= "string" then
		return
	end
	
	local data = { ... }
	
	local boothId = data[1]
	local booth = boothModels[boothId]
	local validBooth = booth and booth:HasTag(Booths.Tag)
	
	if interaction == "Claim" and validBooth then
		return claimAttempt(player, booth)
	elseif interaction == "Edit" and validBooth then
		return editAttempt(player, booth)
	elseif interaction == "Unclaim" then
		return unclaimAttempt(player)
	elseif interaction == "SetTextAttempt" then
		return setTextAttempt(player, ...)
	elseif interaction == "GetBoothsData" then
		return serverBoothsData
	end
end

Booths.init = function()
	playerDataService = Knit.GetService("PlayerDataService")
	service = Knit.GetService("InteractingService")
end

Booths.taggedObjectAdded = function(taggedObject: Instance)
	local id = HttpService:GenerateGUID()
	taggedObject:SetAttribute("Id", id)
	
	serverBoothsData[id] = {
		textData = BoothsData.Defaults.DESCRIPTION_DATA,
	}
	
	boothModels[id] = taggedObject
end

Booths.taggedObjectRemoved = function(taggedObject: Instance)
	local id = table.find(boothModels, taggedObject)
	if not id then
		return
	end
	
	local boothData = serverBoothsData[id]
	if boothData then
		boothData.scope:doCleanup()
		serverBoothsData[id] = nil
	end
	
	boothModels[id] = taggedObject
end

Booths.playerAdded = function(player: Player)
	updateBoothsForPlayer(player)
end

Booths.playerRemoving = function(player: Player)
	local userIdString = tostring(player.UserId)
	if playerBooths[userIdString] then
		playerBooths[userIdString] = nil
	end
	
	for _, boothData in serverBoothsData do
		if boothData.ownerUserId ~= userIdString then
			continue
		end
		boothData.ownerUserId = nil
	end
	
	for _, otherPlayer in Players:GetPlayers() do
		updateBoothsForPlayer(otherPlayer)
	end
end

return Booths