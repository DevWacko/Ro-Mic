local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)

Knit.AddControllers(ReplicatedStorage.Source.Controllers)

Knit.Source = ReplicatedStorage.Source
Knit.Shared = {}

require(Knit.Source.Utils.Runtime)({
	ReplicatedStorage.Packages,
	
	Knit.Source.Utils,
	Knit.Source.Data,
	Knit.Source.Classes,
}, 1)

-- local moduleContainers = {
-- 	Knit.Source.Utils,
-- 	Knit.Source.Data,
-- 	Knit.Source.Classes,
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

Knit.Start():catch(warn)