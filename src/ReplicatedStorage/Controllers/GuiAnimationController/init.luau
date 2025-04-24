-- Services --
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Containers --
local AnimationTypes = script.AnimationTypes
local Packages = ReplicatedStorage.Packages

local Knit = require(Packages.Knit)

--local abbreviateNumber = require(ReplicatedStorage.Source.Utils.Abbreviation.abbreviateNumber)

local animationType = require(AnimationTypes.Type)

-- Controller
local GuiAnimationController = Knit.CreateController { Name = "GuiAnimationController" }

-- Types --
type Self = typeof(GuiAnimationController)
type AnimationType = typeof(animationType)

-- Local --
local player = Players.LocalPlayer

local requiredAnimationModules: { [string]: AnimationType } = {}
local startSizes: { [GuiObject]: UDim2 } = {}

-- function GuiAnimationController:CountLabelTo(label: TextLabel, from: number, to: number, ignoreAbbreviation: boolean?)
-- 	local difference = to - from
-- 	if difference == 0 then
-- 		return to
-- 	end
	
-- 	local value = from
-- 	task.spawn(function()
-- 		while value ~= to do
-- 			value += (difference > 0) and 1 or -1
-- 			label.Text = not ignoreAbbreviation and abbreviateNumber(value) or value
-- 			task.wait()
-- 		end
-- 	end)
-- end

local function manageAddedAnimatedTag(self: Self, taggedObject: GuiObject)
	if not taggedObject:IsDescendantOf(player) then
		return
	end
	for _, animationType in string.split(taggedObject:GetAttribute("AnimationType"), ",") do
		self.activeAnimatedClasses[taggedObject] = requiredAnimationModules[animationType].new(taggedObject)
	end
end

local function manageRemovedAnimatedTag(self: Self, taggedObject: GuiObject)
	local activeClass = self.activeAnimatedClasses[taggedObject]
	if activeClass then
		activeClass:Destroy()
		self.activeAnimatedClasses[taggedObject] = nil
	end
end

function GuiAnimationController:KnitInit()
	self.activeAnimatedClasses = {} :: { [GuiObject]: AnimationType } 
	
	for _, animationTypeModule: ModuleScript in AnimationTypes:GetChildren() do
		requiredAnimationModules[animationTypeModule.Name] = require(animationTypeModule)
	end
	
	local animatedTag = "Animated"
	CollectionService:GetInstanceAddedSignal(animatedTag):Connect(function(obj)
		manageAddedAnimatedTag(self, obj)
	end)
	CollectionService:GetInstanceRemovedSignal(animatedTag):Connect(function(obj)
		manageRemovedAnimatedTag(self, obj)
	end)
	for _, obj in CollectionService:GetTagged(animatedTag) do
		manageAddedAnimatedTag(self, obj)
	end
end

return GuiAnimationController