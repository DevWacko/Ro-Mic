-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Data = require(ReplicatedStorage.Source.Data.Interacting.Booths)

local playerThumbnail = Data.PlayerThumbnail

local Streamable = require(Packages.Streamable).Streamable
local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

-- Main Module --
local Booths = {
	Tag = "Booth",
}

-- Types --
type BoothModel = Model
type BoothInteractionPart = Part & { Claim: ProximityPrompt }
type DescriptionPart = Part & {
	SurfaceGui: SurfaceGui & {
		PlayerAvatar: ImageLabel,
		Description: TextLabel,
	},
}
type StandOwnerPart = Part & {
	SurfaceGui: SurfaceGui & { TextLabel: TextLabel },
}

-- Local --
local player = Players.LocalPlayer
local userIdString = tostring(player.UserId)

local menuController
local controller

local interactingService

local boothTempScopes: { [string]: Fusion.Scope } = {}

local clientBoothsData: { [string]: {
	scope: Fusion.Scope,
	
	ownerUserId: Fusion.Value<string>,
	
	textData: Fusion.Value<{
		text: string,
		textColor: Color3, strokeColor: Color3,
		font: Font, strokeOpacity: number,
	}>,
} } = {}

local mainScope = Fusion:scoped()
local editing: Fusion.Value<boolean> = mainScope:Value(false)
local hasBooth: Fusion.Value<boolean> = mainScope:Value(false)

local cachedBooths: { [number]: Model } = {}

local function boothDataLoaded()
	for i, cachedBooth in cachedBooths do
		table.remove(cachedBooths, i)
		Booths.taggedObjectAdded(cachedBooth)
	end
end

local function manageBoothDataUpdate(sentBoothsData)
	for boothId, boothData in sentBoothsData do
		local clientBoothData = clientBoothsData[boothId]
		if not clientBoothData then
			clientBoothData = {}
			
			local scope = Fusion:scoped()
			clientBoothData.scope = scope
			
			clientBoothData.ownerUserId = scope:Value(boothData.ownerUserId)
			clientBoothData.textData = scope:Value(boothData.textData)
			
			clientBoothsData[boothId] = clientBoothData
		end
		
		local newOwnerUserId = boothData.ownerUserId
		clientBoothData.ownerUserId:set(newOwnerUserId)
		if newOwnerUserId then
			clientBoothData.textData:set(boothData.textData or Data.Defaults.DESCRIPTION_DATA)
		else
			clientBoothData.textData:set(Data.Defaults.DESCRIPTION_DATA)
		end
		
		boothDataLoaded()
	end
end

Booths.init = function()
	menuController = Knit.GetController("MenuController")
	controller = Knit.GetController("InteractingController")
	
	interactingService = Knit.GetService("InteractingService")
	interactingService:InteractAttempt("Booths", "GetBoothsData"):andThen(function(loadedBoothData: {}?)
		if not loadedBoothData then
			return
		end
		manageBoothDataUpdate(loadedBoothData)
	end)
	
	controller:ObserveInteraction("Booths", function(interaction: string, ...)
		local data = { ... }
		if interaction == "CancelEdit" then
			editing:set(false)
		elseif interaction == "UpdateBoothsData" then
			manageBoothDataUpdate(data[1])
		end
	end)
end

local function onBoothInteracted(booth: Model)
	local boothId = booth:GetAttribute("Id")
	
	local boothData = clientBoothsData[boothId]
	if not userIdString then
		return
	end
	
	local ownerUserId: string? = peek(boothData.ownerUserId)
	if ownerUserId == userIdString then
		controller.InteractingService:InteractAttempt("Booths", "Edit", boothId):andThen(function(success: boolean?)
			if not success then
				return
			end
			editing:set(true)
			menuController:SetMenu("TextBooth")
		end)
	elseif not ownerUserId then
		controller.InteractingService:InteractAttempt("Booths", "Claim", boothId)
	end
end

Booths.taggedObjectAdded = function(taggedObject: Instance)
	local boothId = taggedObject:GetAttribute("Id")
	
	local boothData = clientBoothsData[boothId]
	if not boothData then
		if not table.find(cachedBooths, taggedObject) then
			table.insert(cachedBooths, taggedObject)
		end
		return
	end
	local owner = boothData.ownerUserId
	
	local boothInteractionPart: BoothInteractionPart = taggedObject:WaitForChild("BoothInteraction")
	local descriptionPart: DescriptionPart = taggedObject:WaitForChild("Description")
	local standOwnerPart: StandOwnerPart = taggedObject:WaitForChild("StandOwner")
	
	local tempScope: Fusion.Scope = Fusion:scoped()
	
	tempScope:Observer(owner):onBind(function()
		local ownerUserId: string? = peek(owner)
		local newOwner: Player? = ownerUserId and Players:GetPlayerByUserId(tonumber(ownerUserId)) or nil
		standOwnerPart.SurfaceGui.TextLabel.Text = newOwner and newOwner.Name or Data.Defaults.OWNER_LABEL
		
		hasBooth:set(newOwner ~= nil and newOwner == player)
		
		local profileImage: string?
		if newOwner then
			profileImage = Players:GetUserThumbnailAsync(newOwner.UserId, playerThumbnail.TYPE, playerThumbnail.SIZE)
		end
		descriptionPart.SurfaceGui.PlayerAvatar.Image = profileImage or ""
	end)
	
	local function setTextProperties()
		local descPart: Part? = taggedObject:FindFirstChild("Description")
		if not descPart then
			return
		end
		
		local textData = peek(boothData.textData)
		
		local descriptionLabel: TextLabel = descPart:WaitForChild("SurfaceGui"):FindFirstChild("Description")
		descriptionLabel.Text = textData.text or ""
		descriptionLabel.TextColor3 = textData.textColor
		descriptionLabel.FontFace = Font.new(textData.font.Family, textData.weight, textData.style)
		
		local stroke = descriptionLabel:FindFirstChildWhichIsA("UIStroke")
		stroke.Color = textData.strokeColor
		stroke.Transparency = 1 - textData.strokeOpacity
	end
	Streamable.new(taggedObject, "Description"):Observe(setTextProperties)
	boothData.scope:Observer(boothData.textData):onBind(setTextProperties)
	
	tempScope:Hydrate(ReplicatedStorage.Assets.Booths.Claim:Clone()) {
		Enabled = tempScope:Computed(function(use: Fusion.Use)
			local isOwner = use(owner) == tostring(player.UserId)
			if use(editing) or (use(hasBooth) and not isOwner) then
				return false
			elseif isOwner or not use(owner) then
				return true
			end
		end),
		ActionText = tempScope:Computed(function(use: Fusion.Use)
			return use(owner) and "Edit" or "Claim"
		end),
		Parent = boothInteractionPart,
		[OnEvent("Triggered")] = function(player)
			onBoothInteracted(taggedObject)
		end
	}
	
	boothTempScopes[taggedObject] = tempScope
end

Booths.taggedObjectRemoved = function(taggedObject: Instance)
	local scope = boothTempScopes[taggedObject:GetAttribute("Id")]
	if scope then
		scope:doCleanup()
	end
	
	local cachedIndex = table.find(cachedBooths, taggedObject)
	if cachedIndex then
		table.remove(cachedBooths, cachedIndex)
	end
end

return Booths