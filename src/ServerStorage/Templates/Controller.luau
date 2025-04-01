-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Knit = require(Packages.Knit)

-- Controller
local CONTROLLER_NAME = Knit.CreateController { Name = "CONTROLLER_NAME" }

-- Types --
type Self = typeof(CONTROLLER_NAME)

function CONTROLLER_NAME:KnitInit()end

return CONTROLLER_NAME