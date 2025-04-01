local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ExPackages = ReplicatedStorage:WaitForChild("ExPackages")
local Loader = require(ExPackages.Loader)
local Knit = require(ExPackages.Knit)

Loader.LoadDescendants(ServerStorage.Source.Services, function(module)
	return module.Name:match("Service$") ~= nil
end)

Knit.Start():andThen(function()
	print("Knit started!")
end):catch(warn)