local Players = game:GetService("Players")

local Commands = {}

function Commands.MessageIsACommand(chatMessage: string)
	-- Looking for a / inside of the message
	if string.sub(chatMessage, 1, 1) ~= "/" then return end
	return true
end

function Commands.TriggerCommandFromMessage(player: Player, chatMessage: string)
	-- Getting the key from the message
	local stopIndex = string.find(chatMessage, " ")
	if stopIndex then stopIndex -= 1 end
	local key = string.sub(chatMessage, 2, stopIndex)
	
	-- Checking if the command exists as a module
	local mod = Commands.FindCommandModuleFromKey(key)
	if not mod then return end
	
	-- Getting all of the sent in words
	local words = {}
	for i=2, mod.WordsAccepted + 1 do
		words[i - 1] = string.split(chatMessage, " ")[i]
	end
	
	-- Check if there is a player named after the first word
	local foundPlayer;
	for _, setPlayer in Players:GetPlayers() do
		local name = string.lower(words[1] or "me")
		local displayName = string.lower(setPlayer.DisplayName) == name
		local username = string.lower(setPlayer.Name) == name
		if not displayName and not username and name ~= "me" then continue end
		foundPlayer = setPlayer
		table.remove(words, 1)
	end
	if not foundPlayer then foundPlayer = player end
	
	--Triggering the command
	mod.Trigger(foundPlayer, words)
end

function Commands.FindCommandModuleFromKey(key: string)
	for _, mod: ModuleScript? in script:GetChildren() do
		if not mod:IsA("ModuleScript") or mod:HasTag("Ignore") then continue end
		mod = require(mod)
		if mod.Key ~= key then continue end
		return mod
	end
end

return Commands