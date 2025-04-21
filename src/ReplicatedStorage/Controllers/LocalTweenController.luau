local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.ExPackages.Knit)

local LocalTweenController = Knit.CreateController { Name = "LocalTweenController" }

function LocalTweenController:KnitStart()
	self.LocalTweenService.Tween:Connect(function(instance: any, tweenInfo: {
		Time: number,
		Style: Enum.EasingStyle,
		Direction: Enum.EasingDirection,
		Repeat: number,
		Reverse: boolean,
		Delay: number
	}, properties: { [string]: any })
		TweenService:Create(instance, TweenInfo.new(
			tweenInfo.Time,
			tweenInfo.Style,
			tweenInfo.Direction,
			tweenInfo.Repeat,
			tweenInfo.Reverse,
			tweenInfo.Delay
		), properties):Play()
	end)
end

function LocalTweenController:KnitInit()
	self.LocalTweenService = Knit.GetService("LocalTweenService")
end

return LocalTweenController
