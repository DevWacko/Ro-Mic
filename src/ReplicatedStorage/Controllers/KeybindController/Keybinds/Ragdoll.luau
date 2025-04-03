-- Services --
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local coreCall = require(ReplicatedStorage.Source.Utils.Player.coreCall)

-- Main Module --
local Ragdoll = {
	Keys = { Enum.KeyCode.R }
}

-- Local --
local ragdolling = false

local scope: Fusion.Scope = Fusion:scoped()

local ragdollService

local function toggleRagdollAttempt()
	ragdollService:SetRagdollEnabledAttempt(not ragdolling):andThen(function(success: boolean?)
		if not success then
			return
		end
		--print("RAGDOLLING SET TO ", ragdolling)
	end)
end

Ragdoll.init = function()
	ragdollService = Knit.GetService("RagdollService")
	ragdollService.RagdollEnabledChanged:Connect(function(enabled: boolean)
		ragdolling = enabled
		
		local char = Players.LocalPlayer.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then
			return
		end
		
		hum:ChangeState(if ragdolling then Enum.HumanoidStateType.Physics else Enum.HumanoidStateType.GettingUp)
	end)
	
	local actionName = "Ragdoll"
	local function handleAction(actionName, inputState, _inputObject)
		if actionName == actionName and inputState == Enum.UserInputState.Begin then
			toggleRagdollAttempt()
		end
	end
	
	ContextActionService:BindAction(actionName, handleAction, true, Enum.KeyCode.R)
	
	task.delay(0.1, function()
		local button: ImageLabel & {
			ActionIcon: ImageLabel,
			ActionTitle: TextLabel
		} = ContextActionService:GetButton(actionName)
		
		scope:Hydrate(button) {
			AnchorPoint = Vector2.one,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(50, 50),
		}
		scope:Hydrate(button.ActionTitle) {
			TextScaled = true,
			Text = "Ragdoll"
		}
	end)
end

Ragdoll.inputStarted = function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end
	if input.KeyCode == Ragdoll.Keys[1] then
		toggleRagdollAttempt()
	end
end

Ragdoll.inputEnded = function(input: InputObject, gameProcessedEvent: boolean)
	
end

return Ragdoll