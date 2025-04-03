-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Packages --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local peek = Fusion.peek

-- Main Module --
local Booths = {
	Tag = "Booth",
}

-- Local --
local service

local boothsData: { [Model]: {
	scope: Fusion.scope,
	owner: Fusion.Value<Player?>,
} } = {}

local playersWithBooth: { [number]: Player } = {}

local function warning(key: string, ...)
	local data = { ... }
	if key == "BoothData" then
		warn("There was no booth data for the booth: ", data[1])
	end
end

local function dataFromBooth(booth: Model)
	local boothData = boothsData[booth]
	if not boothData then
		warning("BoothData", booth)
		return
	end
	return boothData
end

local function claimAttempt(player: Player, booth: Model)
	local data = dataFromBooth(booth)
	if not data then
		return
	end
	if table.find(playersWithBooth, player) then
		return
	end
	
	local owner = data.owner
	if peek(owner) then
		return
	end
	owner:set(player)
	
	table.insert(playersWithBooth, player)
	
	return true
end

local function editAttempt(player: Player, booth: Model)
	local data = dataFromBooth(booth)
	if not data then
		return
	end
	
	local owner = data.owner
	if peek(owner) ~= player then
		return
	end
	
	return true
end

Booths.sentInteractAttempt = function(player: Player, interaction: string, booth: Model)
	if not interaction or typeof(interaction) ~= "string" then
		return
	end
	if not booth or not booth:HasTag(Booths.Tag) then
		return
	end
	
	if interaction == "Claim" then
		return claimAttempt(player, booth)
	elseif interaction == "Edit" then
		return editAttempt(player, booth)
	end
end

Booths.init = function()
	service = Knit.GetService("InteractingService")
end

Booths.taggedObjectAdded = function(taggedObject: BoothModel)
	local scope = Fusion:scoped()
	local owner = scope:Value(nil)
	
	scope:Observer(owner):onChange(function()
		local newOwner = peek(owner)
		taggedObject:SetAttribute("Owner", newOwner and newOwner.Name or nil)
	end)
	
	boothsData[taggedObject] = {
		scope = scope,
		owner = owner,
	}
end

Booths.taggedObjectRemoved = function(taggedObject: BoothModel)
	local boothData = boothsData[taggedObject]
	if boothData then
		boothData.scope:doCleanup()
		boothsData[taggedObject] = nil
	end
end

Booths.playerRemoving = function(player: Player)
	local index = table.find(playersWithBooth, player)
	if index then
		table.remove(playersWithBooth, index)
	end
	
	for _, boothData in boothsData do
		if peek(boothData.owner) ~= player then
			continue
		end
		boothData.owner:set(nil)
	end
end

return Booths