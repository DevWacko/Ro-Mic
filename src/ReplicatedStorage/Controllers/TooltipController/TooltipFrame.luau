-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children = Fusion.Children

local function TooltipFrame(
	scope: Fusion.Scope,
	tooltip: Fusion.Value<string?>,
	mouseX: Fusion.Value<number>,
	mouseY: Fusion.Value<number>
): Fusion.Child
	return scope:New "CanvasGroup" {
		AnchorPoint = Vector2.yAxis * 0.5,
		Position = scope:Computed(function(use: Fusion.Use)
			return UDim2.fromOffset(use(mouseX), use(mouseY))
		end),
		Size = scope:Spring(scope:Computed(function(use: Fusion.Use)
			return use(tooltip) ~= "" and UDim2.fromScale(0.1, 0.05) or UDim2.fromScale(0, 0.05)
		end), 25, 0.8),
		
		GroupTransparency = scope:Tween(scope:Computed(function(use: Fusion.Use)
			return use(tooltip) ~= "" and 0 or 1
		end), TweenInfo.new(0.2)),
		
		[Children] = {
			scope:New ("UICorner") { CornerRadius = UDim.new(0.2, 0) },
			scope:New "TextLabel" {
				Size = UDim2.fromScale(1, 1),
				
				Text = tooltip,
				TextScaled = true,
			},
		}
	}
end

return TooltipFrame