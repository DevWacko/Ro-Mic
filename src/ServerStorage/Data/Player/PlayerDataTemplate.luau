-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Booths = require(ReplicatedStorage.Source.Data.Interacting.Booths)
local defaultDescriptionData = Booths.Defaults.DESCRIPTION_DATA

local PlayerDataTemplate = {}

PlayerDataTemplate.Values = {
	PlayTime = 0,
	BoothTextData = {
		TextColorIndex = 1, StrokeColorIndex = 1,
		FontIndex = 1,
		StrokeOpacity = 1,
	},
}

return PlayerDataTemplate