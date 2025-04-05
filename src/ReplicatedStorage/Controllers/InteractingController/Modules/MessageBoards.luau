-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Tooltip = require(ReplicatedStorage.Source.Data.Gui.Tooltip)

local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local Children = Fusion.Children
local peek = Fusion.peek

-- Main Module --
local MessageBoards = {
	Tag = "MessageBoard",
}

-- Local --
local player = Players.LocalPlayer

local controller

local scope: Fusion.Scope = Fusion:scoped()
local surfaceGuis: Fusion.Value<{ [number]: {
	name: string,
	messages: Fusion.Value<{ [Player]: string }>
} }> = scope:Value({})

MessageBoards.init = function()
	controller = Knit.GetController("InteractingController")
	scope:New "Folder" {
		Name = "MessageBoardScreenGuis",
		Parent = player:WaitForChild("PlayerGui"),
		[Children] = {
			scope:ForValues(surfaceGuis, function(use: Fusion.Use, scope: Fusion.Scope, name: string)
				return scope:New "SurfaceGui" {
					Name = name,
					
					Brightness = 1,
					
					
				}
			end)
		},
	}
end

MessageBoards.taggedObjectAdded = function(taggedObject: Instance)
	scope:Observer(submittedMessages):onBind(function()
		
	end)
	
	local newSurfaceGuis = peek(surfaceGuis)
	table.insert(newSurfaceGuis, taggedObject.Name)
	surfaceGuis:set(newSurfaceGuis)
	
	local clickDetector: ClickDetector = taggedObject:FindFirstChildWhichIsA("ClickDetector")
	table.insert(scope, clickDetector.MouseClick:Connect(function()
		taggedObject:RemoveTag(Tooltip.OBJECT_TAG)
	end))
end

MessageBoards.taggedObjectRemoved = function(taggedObject: Instance)
	scope:doCleanup()
end

return MessageBoards