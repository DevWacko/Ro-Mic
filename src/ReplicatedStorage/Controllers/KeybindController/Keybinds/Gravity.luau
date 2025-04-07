-- Services --
local ContentProvider = game:GetService("ContentProvider")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Modules --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

local peek = Fusion.peek

-- Main Module --
local Gravity = {
	Keys = { Enum.KeyCode.F }
}

-- Local --
local scope: Fusion.Scope = Fusion:scoped()
local floating: Fusion.Value<boolean> = scope:Value(false)

local char: Model?

local gravity = workspace.Gravity

Gravity.init = function()
	scope:Observer(floating):onBind(function()
		if not char then
			return
		end
		workspace.Gravity = peek(floating) and 1 or gravity
	end)
	
	if UserInputService.KeyboardEnabled then
		return
	end
	
	local actionName = "Float"
	local function handleAction(actionName, inputState, _inputObject)
		if actionName == actionName and inputState == Enum.UserInputState.Begin then
			floating:set(not peek(floating))
		end
	end
	
	ContextActionService:BindAction(actionName, handleAction, true, Enum.KeyCode.F)
	
	task.delay(0.1, function()
		local button: ImageLabel & {
			ActionIcon: ImageLabel,
			ActionTitle: TextLabel
		} = ContextActionService:GetButton(actionName)
		
		scope:Hydrate(button) {
			AnchorPoint = Vector2.one,
			Position = UDim2.fromScale(0.8, 0.3),
			Size = UDim2.fromOffset(50, 50),
		}
		scope:Hydrate(button.ActionTitle) {
			TextScaled = true,
			Text = "Float"
		}
	end)
end

Gravity.characterAdded = function(addedChar: Model)
	floating:set(false)
	char = addedChar
end

Gravity.inputStarted = function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end
	floating:set(not peek(floating))
end

return Gravity