local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ExPackages = ReplicatedStorage:WaitForChild("ExPackages")
local Knit = require(ExPackages.Knit)

Knit.AddServices(ServerStorage.Source.Services)

Knit.Source = ServerStorage.Source
Knit.SharedSource = ReplicatedStorage.Source

Knit.Data = Knit.Source.Data
Knit.SharedData = Knit.SharedSource.Data

Knit.Utils = Knit.Source.Utils
Knit.SharedUtils = Knit.SharedSource.Utils

Knit.Start():catch(warn)