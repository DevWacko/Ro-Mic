local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)

Knit.AddServices(ServerStorage.Source.Services)

Knit.SharedSource = ReplicatedStorage.Source
Knit.Source = ServerStorage.Source
Knit.Shared = {}

require(Knit.SharedSource.Utils.Runtime)({
	ReplicatedStorage.Packages,
	
	Knit.SharedSource.Utils,
	Knit.SharedSource.Data,
	Knit.SharedSource.Classes,
}, 1)

-- Knit.SharedSource = ReplicatedStorage.Source
-- Knit.Shared = {}

-- local moduleContainers = {
-- 	Knit.Source.Modules.Data,
-- 	Knit.Source.Modules.Utils,
-- }
-- local sharedModuleContainers = {
-- 	Knit.SharedSource.Utils,
-- 	Knit.SharedSource.Data,
-- 	Knit.SharedSource.Classes,
-- }

-- local function loadFolder(folder: Folder, modulesTable: {})
-- 	for _, instance: (ModuleScript | Folder)? in folder:GetChildren() do
-- 		if instance:IsA("ModuleScript") then
-- 			modulesTable[instance.Name] = require(instance)
-- 		elseif instance:IsA("Folder") then
-- 			loadFolder(instance, modulesTable)
-- 		end
-- 	end
-- end
-- for _, container in moduleContainers do
-- 	local loadedModules = {}
-- 	loadFolder(container, loadedModules)
-- 	Knit[container.Name] = loadedModules
-- end
-- for _, container in sharedModuleContainers do
-- 	local loadedModules = {}
-- 	loadFolder(container, loadedModules)
-- 	Knit.Shared[container.Name] = loadedModules
-- end

Knit.Start():catch(warn)