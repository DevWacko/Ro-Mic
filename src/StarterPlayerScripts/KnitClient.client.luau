local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local WaitFor = require(Packages.WaitFor)
local Loader = require(Packages.Loader)
local Knit = require(Packages.Knit)

WaitFor.Child(ReplicatedStorage, "Source"):andThen(function(source: Folder)
	Loader.LoadDescendants(source.Controllers, function(module)
		return module.Name:match("Controller$") ~= nil
	end)
end):catch(warn)

Knit.Start():andThen(function()
	print("Knit started!")
end):catch(warn)