-- Services --
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Tooltip = require(ReplicatedStorage.Source.Data.Gui.Tooltip)

local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

local Children = Fusion.Children

local TooltipFrame = require(script.TooltipFrame)

-- Controller
local TooltipController = Knit.CreateController { Name = "TooltipController" }

-- Types --
type Self = typeof(TooltipController)

-- Local --
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local char: Model?

local camera = workspace.CurrentCamera

local taggedObjects: { [number]: Instance } = {}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function taggedObjectAdded(taggedObject: Instance)
	table.insert(taggedObjects, taggedObject)
end

local function taggedObjectRemoved(taggedObject: Instance)
	local index = table.find(taggedObjects, taggedObject)
	if index then
		table.remove(taggedObjects, index)
	end
end

function TooltipController:KnitInit()
	self.scope = Fusion:scoped() :: Fusion.Scope
	self.tooltip = self.scope:Value("") :: Fusion.Value<string?>
	local mouseX: Fusion.Value<number>, mouseY: Fusion.Value<number> = self.scope:Value(0), self.scope:Value(0)
	
	self.scope:New "ScreenGui" {
		Name = "Tooltip",
		Parent = player:WaitForChild("PlayerGui"),
		[Children] = {
			TooltipFrame(self.scope, self.tooltip, mouseX, mouseY),
		},
	}
	
	local tag = Tooltip.OBJECT_TAG
	CollectionService:GetInstanceAddedSignal(tag):Connect(taggedObjectAdded)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(taggedObjectRemoved)
	for _, taggedObject in CollectionService:GetTagged(tag) do
		taggedObjectAdded(taggedObject)
	end
	
	local function charAdded(addedChar: Model)
		char = addedChar
	end
	player.CharacterAdded:Connect(charAdded)
	if player.Character then
		charAdded(player.Character)
	end
	
	RunService.RenderStepped:Connect(function()
		if not char then
			return
		end
		
		mouseX:set(mouse.X + Tooltip.MOUSE_X_OFFSET)
		mouseY:set(mouse.Y + Tooltip.MOUSE_Y_OFFSET)
		
		raycastParams.FilterDescendantsInstances = { char:GetDescendants() }
		
		local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
		-- local origin = char:GetPivot().Position
		-- local direction = mouse.Hit.Position
		local result: RaycastResult? = workspace:Raycast(ray.Origin, ray.Direction * Tooltip.OBJECT_TOOLTIP_DISTANCE, raycastParams)
		
		if not result then
			self.tooltip:set("")
			return
		end
		
		local instance = result.Instance
		for _, taggedObject in taggedObjects do
			if not instance:IsAncestorOf(taggedObject) and instance ~= taggedObject then
				continue
			end
			
			self.tooltip:set(taggedObject:GetAttribute(Tooltip.TEXT_ATTRIBUTE_NAME))
			
			return
		end
		
		self.tooltip:set("")
	end)
end

return TooltipController