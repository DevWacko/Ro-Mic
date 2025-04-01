-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Modules --
local Data = require(ServerStorage.Source.Data.Booths)

local playerThumbnail = Data.PlayerThumbnail

local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

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
local boothScopes: { [Model]: Fusion.Scope } = {}

local boothsData: { [Model]: {
	owner: Fusion.Value<Player?>,
} } = {}

Booths.init = function()
	
end

local function onBoothInteracted(player: Player, booth: Model)
	local boothData = boothsData[booth]
	
	local owner = peek(boothData.owner)
	if owner == player then
		
	elseif owner == nil then
		boothData.owner:set(player)
	end
end

Booths.taggedObjectAdded = function(taggedObject: BoothModel)
	local boothInteractionPart: BoothInteractionPart = taggedObject:WaitForChild("BoothInteraction")
	local descriptionPart: DescriptionPart = taggedObject:WaitForChild("Description")
	local standOwnerPart: StandOwnerPart = taggedObject:WaitForChild("StandOwner")
	
	local scope: Fusion.Scope = Fusion:scoped()
	
	local owner = scope:Value(nil)
	scope:Observer(owner):onBind(function()
		local newOwner: Player? = peek(owner)
		standOwnerPart.SurfaceGui.TextLabel.Text = newOwner and newOwner.Name or Data.Defaults.OWNER_LABEL
		
		local profileImage: string?
		if newOwner then
			profileImage = Players:GetUserThumbnailAsync(newOwner.UserId, playerThumbnail.TYPE, playerThumbnail.SIZE)
		end
		descriptionPart.SurfaceGui.PlayerAvatar.Image = profileImage or ""
	end)
	
	boothsData[taggedObject] = {
		owner = owner,
	}
	
	scope:Hydrate(boothInteractionPart:FindFirstChild("Claim")) {
		[OnEvent("Triggered")] = function(player)
			onBoothInteracted(player, taggedObject)
		end
	}
	
	boothScopes[taggedObject] = scope
end

Booths.taggedObjectRemoved = function(taggedObject: BoothModel)
	local scope = boothScopes[taggedObject]
	if scope then
		scope:doCleanup()
		boothScopes[taggedObject] = nil
	end
end

Booths.playerRemoving = function(player: Player)
	for _, boothData in boothsData do
		if peek(boothData.owner) ~= player then
			continue
		end
		boothData.owner:set(nil)
	end
end

return Booths