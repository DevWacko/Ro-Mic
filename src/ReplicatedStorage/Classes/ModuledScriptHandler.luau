-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Class --
local ModuledScriptHandler = {}
ModuledScriptHandler.__index = ModuledScriptHandler

-- Types --
type Self = typeof(ModuledScriptHandler)

function ModuledScriptHandler.new(modulesContainer: Instances)
	local self = setmetatable({}, ModuledScriptHandler)
	self:init(modulesContainer)
	return self
end

function ModuledScriptHandler:init(modulesContainer: Instance)
	local requiredModules: { [string]: { any } } = {}
	for _, module: ModuleScript in modulesContainer:GetChildren() do
		requiredModules[module.Name] = require(module)
	end
	self.requiredModules = requiredModules
	
	self:CallModulesFunction("init")
end

function ModuledScriptHandler:CallModulesFunction(funcKey: string, ...)
	for _, mod in self.requiredModules do
		local func = mod[funcKey]
		if func then
			task.spawn(func, ...)
		end
	end
end

function ModuledScriptHandler:Destroy()
	ModuledScriptHandler:CallModulesFunction("cleanup")
	self.requiredModules = nil
end

return ModuledScriptHandler