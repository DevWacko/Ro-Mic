local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Loader = require(Packages.Loader)
local Knit = require(Packages.Knit)

Loader.LoadDescendants(ServerStorage.Source.Services, function(module)
	return module.Name:match("Service$") ~= nil
end)

Knit.Start():andThen(function()
	print("Knit started!")
end):catch(warn)