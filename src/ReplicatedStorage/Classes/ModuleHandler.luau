-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Class --
local ModuleHandler = {}
ModuleHandler.__index = ModuleHandler

-- Types --
type Self = typeof(ModuleHandler)

function ModuleHandler.new(modulesContainer: Instances)
	local self = setmetatable({}, ModuleHandler)
	self:init(modulesContainer)
	return self
end

function ModuleHandler:init(modulesContainer: Instance)
	local requiredModules: { [string]: { any } } = {}
	for _, module: ModuleScript in modulesContainer:GetChildren() do
		requiredModules[module.Name] = require(module)
	end
	self.requiredModules = requiredModules
	
	self:CallModulesFunction("init")
end

function ModuleHandler:CallModulesFunction(funcKey: string, ...)
	for _, mod in self.requiredModules do
		local func = mod[funcKey]
		if func then
			task.spawn(func, ...)
		end
	end
end

function ModuleHandler:Destroy()
	ModuleHandler:CallModulesFunction("cleanup")
	self.requiredModules = nil
end

return ModuleHandler