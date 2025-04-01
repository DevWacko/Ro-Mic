-- Services --
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

local ModuledScriptHandler =  require(ReplicatedStorage.Source.Classes.ModuledScriptHandler)

-- Service --
local InteractingService = Knit.CreateService { Name = "InteractingService" }

-- Types --
type Self = typeof(InteractingService)

-- Local --

function InteractingService:KnitInit()
	self.modulesHandler = ModuledScriptHandler.new(script.Modules)
	for name, module: { Tag: string } in self.modulesHandler.requiredModules do
		if name == "Module" then
			continue
		end
		
		local tag = module.Tag
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedObject: Instance)
			self.modulesHandler:CallModulesFunction("taggedObjectAdded", taggedObject)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(taggedObject: Instance)
			self.modulesHandler:CallModulesFunction("taggedObjectRemoved", taggedObject)
		end)
		for _, taggedObject: Instance in CollectionService:GetTagged(tag) do
			self.modulesHandler:CallModulesFunction("taggedObjectAdded", taggedObject)
		end
	end
	
	Players.PlayerRemoving:Connect(function(player)
		self.modulesHandler:CallModulesFunction("playerRemoving", player)
	end)
end

return InteractingService