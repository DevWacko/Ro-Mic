local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerProfilesData = require(ReplicatedStorage.Source.Data.Interacting.PlayerProfiles)

local HighlightController = Knit.CreateController { Name = "HighlightController" }

local highlightedObjects: { [Instance]: Highlight } = {}

local player = Players.LocalPlayer

local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local lastCharacterSelected: Model? = nil

function HighlightController:KnitStart()
	
end

local function removeLastPlayerHighlight()
	if lastCharacterSelected ~= nil then
		HighlightController:RemoveObjectHighlight(lastCharacterSelected)
	end
end

function HighlightController:UpdateCharacterHighlights()
	local char = player.Character
	if not char then
		return
	end
	
	raycastParams.FilterDescendantsInstances = { char:GetDescendants() }
	
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	if not result or not result.Instance then
		removeLastPlayerHighlight()
		return
	end
	
	local otherChar: Model? = result.Instance.Parent
	local otherPlayer = Players:GetPlayerFromCharacter(otherChar)
	if not otherPlayer then
		removeLastPlayerHighlight()
		return
	end
	
	if (char:GetPivot().Position - otherChar:GetPivot().Position).Magnitude > PlayerProfilesData.MAX_VIEW_DISTANCE then
		removeLastPlayerHighlight()
		return
	end
	
	if not self:HasHighlight(otherChar) then
		self:HighlightObject(otherChar, {
			FillTransparency = 1
		})
		lastCharacterSelected = otherChar
	end
end

function HighlightController:HasHighlight(object: Instance)
	return highlightedObjects[object]
end

function HighlightController:HighlightObject(object: Instance, properties: { [string]: any }?)
	local hl = Instance.new("Highlight")
	if properties then
		for key, value in properties do
			hl[key] = value
		end
	end
	hl.Adornee = object
	hl.Parent = object
	
	highlightedObjects[object] = hl
end

function HighlightController:RemoveObjectHighlight(object: Instance)
	local hl = highlightedObjects[object]
	if hl then
		hl:Destroy()
		highlightedObjects[object] = nil
	end
end

function HighlightController:KnitInit()
	RunService.Heartbeat:Connect(function()
		self:UpdateCharacterHighlights()
	end)
end

return HighlightController