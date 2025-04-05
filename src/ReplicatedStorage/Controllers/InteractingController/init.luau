-- Services --
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Signal = require(ExPackages.Signal)
local Knit = require(ExPackages.Knit)

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Controller
local InteractingController = Knit.CreateController { Name = "InteractingController" }
InteractingController.Interacted = Signal.new()

-- Types --
type Self = typeof(InteractingController)

function InteractingController:ObserveInteraction(key: string, handler: (any) -> (any))
	return self.Interacted:Connect(function(interactionKey: string, ...)
		if interactionKey == key then
			handler(...)
		end
	end)
end

function InteractingController:KnitInit()
	self.modulesHandler = ModuleHandler.new(script.Modules)
	for name, module: { Tag: string } in self.modulesHandler.requiredModules do
		if name == "Module" then
			continue
		end
		
		local function added(taggedObject: Instance)
			local taggedObjectAdded = module.taggedObjectAdded
			if taggedObjectAdded then
				taggedObjectAdded(taggedObject)
			end
		end
		
		local tag = module.Tag
		CollectionService:GetInstanceAddedSignal(tag):Connect(added)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(taggedObject: Instance)
			self.modulesHandler:CallModulesFunction("taggedObjectRemoved", taggedObject)
		end)
		for _, taggedObject: Instance in CollectionService:GetTagged(tag) do
			added(taggedObject)
		end
	end
	
	self.InteractingService = Knit.GetService("InteractingService")
	self.InteractingService.Interaction:Connect(function(key: string, ...)
		self.Interacted:Fire(key, ...)
	end)
	
	Players.PlayerAdded:Connect(function(player)
		self.modulesHandler:CallModulesFunction("playerAdded", player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.modulesHandler:CallModulesFunction("playerRemoving", player)
	end)
end

return InteractingController