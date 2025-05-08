local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local scoped, peek = Fusion.scoped, Fusion.peek

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
	
	local indicatorSizes = {}
	for _, indicatorFrame in mainFrame:GetChildren() do
		local keyString = indicatorFrame:GetAttribute("Keybind")
		if not keyString then
			continue
		end
		
		local size = scope:Value(indicatorFrame.Size)
		
		scope:Hydrate(indicatorFrame) {
			Size = scope:Spring(size, 25, 0.7)
		}
		
		indicatorSizes[keyString] = {
			StartSize = indicatorFrame.Size,
			Size = size,
		}
	end
	
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		--[[ if gameProcessedEvent then
			return
		end ]]
		local data = indicatorSizes[input.KeyCode.Name]
		if data then
			data.Size:set(data.StartSize - UDim2.fromScale(0.1, 0.1))
		end
	end)
	UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		--[[ if gameProcessedEvent then
			return
		end ]]
		local data = indicatorSizes[input.KeyCode.Name]
		if data then
			data.Size:set(data.StartSize)
		end
	end)
end

return DesktopIndicator