-- Services --
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Signal = require(Packages.Signal)
local Knit = require(Packages.Knit)

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

function InteractingController:SetupClasses()
	local requiredInteractClasses = {}
	for _, interactClassMod: ModuleScript in script.Classes:GetChildren() do
		requiredInteractClasses[interactClassMod.Name] = require(interactClassMod)
	end
	
	for tag, interactClass in requiredInteractClasses do
		local function added(taggedObject: Instance)
			table.insert(self.interactClasses, interactClass.new(taggedObject))
		end
		
		CollectionService:GetInstanceAddedSignal(tag):Connect(added)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(taggedObject: Instance)
			self.modulesHandler:CallModulesFunction("taggedObjectRemoved", taggedObject)
		end)
		for _, taggedObject: Instance in CollectionService:GetTagged(tag) do
			added(taggedObject)
		end
	end
end

function InteractingController:KnitInit()
	local idCounter = 0
	
	Knit.Shared.Interactables = {}
	for tag, class in Knit.Classes.Interactable do
		local function added(taggedObject: Instance)
			class.new(taggedObject, idCounter)
			idCounter += 1
		end
		local function removed(taggedObject: Instance)
			local oldClass = Knit.Shared.Interactables[taggedObject:GetAttribute("Id")]
			if oldClass then
				oldClass:Destroy()
				Knit.Shared.Interactables[oldClass] = nil
			end
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(added)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(removed)
		for _, taggedObject in CollectionService:GetTagged(tag) do
			added(taggedObject)
		end
	end
	
	self.modulesHandler = ModuleHandler.new(script.Modules)
	self.interactClasses = {}
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
	self:SetupClasses()
	
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