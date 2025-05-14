local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local scoped, peek = Fusion.scoped, Fusion.peek

local player = Players.LocalPlayer

-- Main Module --
local DesktopIndicator = { MenuName = "DesktopIndicator" }

DesktopIndicator.shown = function(menu: ScreenGui, ...)
	
end

DesktopIndicator.menuLoaded = function(menu: ScreenGui)
	local mainFrame: Frame = menu:FindFirstChild("Main")
	
	if not UserInputService.KeyboardEnabled then
		mainFrame.Visible = false
		return
	end
	
	local scope = scoped(Fusion, {})
	
	local char: Model? = player.Character
	table.insert(scope, player.CharacterAdded:Connect(function(addedChar)
		char = addedChar
	end))
	
	local indicatorSizes = {}
	for _, indicatorFrame in mainFrame:GetChildren() do
		local keyString = indicatorFrame:GetAttribute("Keybind")
		if not keyString then
			continue
		end
		
		local size = scope:Value(indicatorFrame.Size)
		local sizeSpring = scope:Spring(size, 25, 0.7)
		
		scope:Hydrate(indicatorFrame) {
			Size = sizeSpring
		}
		
		indicatorSizes[keyString] = {
			StartSize = indicatorFrame.Size,
			Size = sizeSpring,
		}
	end
	
	table.insert(scope, char:GetAttributeChangedSignal("Ragdolled"):Connect(function()
		local data = indicatorSizes.R
		if data then
			data.Size:addVelocity(-UDim2.fromScale(0.1, 0.1))
		end
	end))
	table.insert(scope, char:GetAttributeChangedSignal("Floating"):Connect(function()
		local data = indicatorSizes.F
		if data then
			data.Size:addVelocity(-UDim2.fromScale(0.1, 0.1))
		end
	end))
	--[[ UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		local data = indicatorSizes[input.KeyCode.Name]
		if data then
			data.Size:set(data.StartSize)
		end
	end) ]]
end

return DesktopIndicator