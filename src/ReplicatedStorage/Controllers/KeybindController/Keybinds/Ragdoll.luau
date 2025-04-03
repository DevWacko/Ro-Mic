-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Knit = require(ReplicatedStorage.ExPackages.Knit)

local Ragdoll = {
	Keys = { Enum.KeyCode.R }
}

-- Local --
local ragdolling = false

local ragdollService

Ragdoll.init = function()
	ragdollService = Knit.GetService("RagdollService")
	ragdollService.RagdollEnabledChanged:Connect(function(enabled: boolean)
		ragdolling = enabled
	end)
end

Ragdoll.inputStarted = function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end
	if input.KeyCode == Ragdoll.Keys[1] then
		ragdollService:SetRagdollEnabledAttempt(not ragdolling):andThen(function(success: boolean?)
			if not success then
				return
			end
			--print("RAGDOLLING SET TO ", ragdolling)
		end)
	end
end

Ragdoll.inputEnded = function(input: InputObject, gameProcessedEvent: boolean)
	
end

return Ragdoll