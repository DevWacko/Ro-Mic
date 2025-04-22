local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExPackages = ReplicatedStorage:WaitForChild("ExPackages")
local Knit = require(ExPackages.Knit)

Knit.AddControllers(ReplicatedStorage.Source.Controllers)

Knit.Source = ReplicatedStorage.Source
Knit.Classes = Knit.Source.Classes
Knit.Data = Knit.Source.Data
Knit.Utils = Knit.Source.Utils

Knit.Start():catch(warn)