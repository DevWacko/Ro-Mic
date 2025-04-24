-- Services --
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Knit = require(Packages.Knit)

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Controller
local GuiTagController = Knit.CreateController { Name = "GuiTagController" }

-- Types --
type Self = typeof(GuiTagController)

-- Local --
local player = Players.LocalPlayer

function GuiTagController:KnitInit()
	local handler = ModuleHandler.new(script.GuiTags)
	for name, module: { Tag: string } in handler.requiredModules do
		if name == "GuiTag" then
			continue
		end
		
		local function added(taggedObject: Instance)
			if not taggedObject:IsDescendantOf(player) then
				return
			end
			local taggedObjectAdded = module.taggedObjectAdded
			if taggedObjectAdded then
				taggedObjectAdded(taggedObject)
			end
		end
		
		local tag = module.Tag
		CollectionService:GetInstanceAddedSignal(tag):Connect(added)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(taggedObject: Instance)
			handler:CallModulesFunction("taggedObjectRemoved", taggedObject)
		end)
		for _, taggedObject: Instance in CollectionService:GetTagged(tag) do
			added(taggedObject)
		end
	end
end

return GuiTagController