-- Services --
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Signal = require(ExPackages.Signal)
local Knit = require(ExPackages.Knit)

local ModuleHandler =  require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Service --
local InteractingService = Knit.CreateService {
	Name = "InteractingService",
	Client = {
		Interaction = Knit.CreateSignal(),
	}
}
InteractingService.InteractionAttemptSent = Signal.new()

-- Types --
type Self = typeof(InteractingService)

function InteractingService.Client:InteractAttempt(...)
	return self.Server:InteractAttempt(...)
end

function InteractingService:InteractAttempt(player: Player, key: string, ...)
	if not key or type(key) ~= "string" then
		return
	end
	for modKey, mod in self.modulesHandler.requiredModules do
		if modKey ~= key then
			continue
		end
		return mod.sentInteractAttempt(player, ...)
	end
end

function InteractingService:ObserveInteractAttempt(key: string, handler: (any) -> (any))
	return self.InteractionAttemptSent:Connect(function(player: Player, sentKey: string, ...)
		if sentKey ~= key then
			return
		end
		handler(player, ...)
	end)
end

function InteractingService:KnitInit()
	self.modulesHandler = ModuleHandler.new(script.Modules)
	for name, module: { Tag: string } in self.modulesHandler.requiredModules do
		if name == "Module" then
			continue
		end
		
		local function added(taggedObject: Instance)
			local taggedObjectAddedFunc = module.taggedObjectAdded
			if taggedObjectAddedFunc then
				taggedObjectAddedFunc(taggedObject)
			end
		end
		
		local tag = module.Tag
		CollectionService:GetInstanceAddedSignal(tag):Connect(added)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(taggedObject: Instance)
			local taggedObjectRemovedFunc = module.taggedObjectRemoved
			if taggedObjectRemovedFunc then
				taggedObjectRemovedFunc(taggedObject)
			end
			self.modulesHandler:CallModulesFunction("taggedObjectRemoved", taggedObject)
		end)
		for _, taggedObject: Instance in CollectionService:GetTagged(tag) do
			added(taggedObject)
		end
	end
	
	Players.PlayerAdded:Connect(function(player)
		self.modulesHandler:CallModulesFunction("playerAdded", player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.modulesHandler:CallModulesFunction("playerRemoving", player)
	end)
end

return InteractingService