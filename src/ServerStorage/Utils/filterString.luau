-- Services --
local TextService = game:GetService("TextService")

-- Functions --
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

return onInputReceived