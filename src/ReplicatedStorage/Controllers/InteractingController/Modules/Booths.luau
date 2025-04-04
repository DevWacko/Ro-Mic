-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Data = require(ReplicatedStorage.Source.Data.Booths)

local playerThumbnail = Data.PlayerThumbnail

local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

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

local menuController
local controller

local boothScopes: { [Model]: Fusion.Scope } = {}

local boothsData: { [Model]: {
	scope: Fusion.Scope,
	owner: Fusion.Value<Player?>
} } = {}

local mainScope = Fusion:scoped()
local editing: Fusion.Value<boolean> = mainScope:Value(false)

Booths.init = function()
	menuController = Knit.GetController("MenuController")
	controller = Knit.GetController("InteractingController")
	
	controller:ObserveInteraction("Booths", function(interaction: string)
		if interaction == "CancelEdit" then
			editing:set(false)
		end
	end)
end

local function onBoothInteracted(booth: Model)
	local boothData = boothsData[booth]
	if not boothData then
		return
	end
	
	local owner: Player? = peek(boothData.owner)
	if owner == player then
		controller.InteractingService:InteractAttempt("Booths", "Edit", booth):andThen(function(success: boolean?)
			if not success then
				return
			end
			editing:set(true)
			menuController:SetMenu(player.PlayerGui:WaitForChild("TextBooth"))
		end)
	elseif not owner then
		controller.InteractingService:InteractAttempt("Booths", "Claim", booth):andThen(function(success: boolean)
			if not success then
				return
			end
			boothsData[booth].owner:set(player)
		end)
	end
end

Booths.taggedObjectAdded = function(taggedObject: Instance)
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
	
	local function setOwner()
		local ownerName = taggedObject:GetAttribute("Owner")
		owner:set(ownerName and Players:FindFirstChild(ownerName) or nil)
	end
	table.insert(scope, taggedObject:GetAttributeChangedSignal("Owner"):Connect(function()
		setOwner()
	end))
	setOwner()
	
	boothsData[taggedObject] = {
		scope = scope,
		owner = owner,
	}
	
	scope:Hydrate(ReplicatedStorage.Assets.Booths.Claim:Clone()) {
		Enabled = scope:Computed(function(use: Fusion.Use)
			local isEditing = use(editing)
			local owner = use(owner)
			local isOwner = owner == Players.LocalPlayer
			
			if isEditing then
				return false
			end
			return isOwner or not owner
		end),
		ActionText = scope:Computed(function(use: Fusion.Use)
			return use(owner) and "Edit" or "Claim"
		end),
		Parent = boothInteractionPart,
		[OnEvent("Triggered")] = function(player)
			if player ~= Players.LocalPlayer then
				return
			end
			onBoothInteracted(taggedObject)
		end
	}
	
	boothScopes[taggedObject] = scope
end

Booths.taggedObjectRemoved = function(taggedObject: Instance)
	local boothData = boothScopes[taggedObject]
	if boothData then
		boothsData.scope:doCleanup()
	end
end

return Booths