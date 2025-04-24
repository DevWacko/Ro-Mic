local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local LocalTweenService = Knit.CreateService {
	Name = "LocalTweenService",
	Client = {
		Tween = Knit.CreateSignal(),
	},
}
type Self = typeof(LocalTweenService)

local function TweenEnded(self: Self, instance: any, properties: { [string]: any })
	self.Threads[instance] = nil
	for i, property in properties do
		instance[i] = property
	end
end

function LocalTweenService:CancelTween(instance: any)
	if self.Threads[instance] ~= nil then
		task.cancel(self.Threads[instance])
		self.Threads[instance] = nil
	end
end

function LocalTweenService:Tween(instance: any, tweenInfo: TweenInfo?, properties: { [string]: any })
	self:CancelTween(instance)
	
	tweenInfo = tweenInfo or TweenInfo.new()
	tweenInfo = {
		Time = tweenInfo.Time,
		Style = tweenInfo.EasingStyle,
		Direction = tweenInfo.EasingDirection,
		Repeat = tweenInfo.RepeatCount,
		Reverse = tweenInfo.Reverses,
		Delay = tweenInfo.DelayTime
	}
	for _, player in Players:GetPlayers() do
		self.Client.Tween:Fire(player, instance, tweenInfo, properties)
	end
	
	if tweenInfo.Reverse == true then
		return
	end
	local repeatCount = tweenInfo.Repeat or 0
	if repeatCount < 0 then
		return
	end
	
	local delayTime = tweenInfo.Delay or 0
	local tweenTime = tweenInfo.Time or 1
	self.Threads[instance] = task.delay((delayTime + tweenTime) * (repeatCount + 1), TweenEnded, self, instance, properties)
end

function LocalTweenService:KnitStart()
	
end

function LocalTweenService:KnitInit()
	self.Threads = {} :: { [any]: thread }
end

return LocalTweenService
