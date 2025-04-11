-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Knit = require(ReplicatedStorage.ExPackages.Knit)

local Command = {
	Key = "set";
	
	WordsAccepted = 3;
}

function Command.Trigger(player: Player, words: {string})
	Knit.GetService("PlayerDataService"):SetValue(player, words[1], tonumber(words[2]))
	return true
end

return Command
