local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExPackages = ReplicatedStorage:WaitForChild("ExPackages")
local WaitFor = require(ExPackages.WaitFor)
local Loader = require(ExPackages.Loader)
local Knit = require(ExPackages.Knit)

WaitFor.Child(ReplicatedStorage, "Source"):andThen(function(source: Folder)
	Loader.LoadDescendants(source.Controllers, function(module)
		return module.Name:match("Controller$") ~= nil
	end)
end):catch(warn)

Knit.Start():andThen(function()
	print("Knit started!")
end):catch(warn)