-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Knit = require(ExPackages.Knit)

-- Service --
local SERVICE_NAME = Knit.CreateService { Name = "SERVICE_NAME" }

-- Types --
type Self = typeof(SERVICE_NAME)

function SERVICE_NAME:KnitInit()end

return SERVICE_NAME