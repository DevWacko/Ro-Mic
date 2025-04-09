-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Booths = require(ReplicatedStorage.Source.Data.Interacting.Booths)

local PlayerDataTemplate = {}

PlayerDataTemplate.Values = {
	PlayTime = 0,
	BoothTextData = {
		
	},
}

return PlayerDataTemplate