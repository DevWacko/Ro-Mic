-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Trove = require(ExPackages.Trove)
local Knit = require(ExPackages.Knit)

local peek = Fusion.peek

local Data = require(ReplicatedStorage.Source.Data.Interacting.PlayerProfiles)

-- Main Module --
local PlayerProfiles = {
	Tag = "ViewableProfile",
}

-- Local --
local player = Players.LocalPlayer

local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local menuController
local controller

local interactingService

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local scope = Fusion:scoped()
local playerSelected: Fusion.Value<Player?> = scope:Value(nil)
local playerViewing: Fusion.Value<Player?> = scope:Value(nil)

PlayerProfiles.init = function()
	menuController = Knit.GetController("MenuController")
	controller = Knit.GetController("InteractingController")
	
	interactingService = Knit.GetService("InteractingService")
	
	local viewingTrove = Trove.new()
	
	local tagCon: RBXScriptConnection?
	scope:Observer(playerViewing):onChange(function()
		viewingTrove:Clean()
		
		local playerProfileMenu: ScreenGui = player:WaitForChild("PlayerGui"):WaitForChild("PlayerProfile")
		viewingTrove:Add(menuController:ObserveMenuClosing("PlayerProfile", function()
			playerViewing:set(nil)
		end))
		
		local currentViewing: Player = peek(playerViewing)
		if currentViewing then
			tagCon = currentViewing.CharacterRemoving:Connect(function()
				playerViewing:set(nil)
			end)
			menuController:SetMenu("PlayerProfile", peek(playerViewing))
		else
			if tagCon then
				tagCon:Disconnect()
				tagCon = nil
			end
			menuController:CloseMenu("PlayerProfile")
		end
	end)
	
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if peek(playerViewing) == peek(playerSelected) then
				playerViewing:set(nil)
			else
				interactingService:InteractAttempt("PlayerProfiles", "ViewProfileAttempt", peek(playerSelected)):andThen(function(success: boolean)
					if not success then
						return
					end
					playerViewing:set(peek(playerSelected))
				end)
			end
		end
	end)
	
	RunService.Heartbeat:Connect(function()
		local char = player.Character
		if not char then
			return
		end
		raycastParams.FilterDescendantsInstances = { char:GetDescendants() }
		
		local currentViewing: Player? = peek(playerViewing)
		if currentViewing then
			local charViewing: Model? = currentViewing.Character
			if not charViewing or (charViewing:GetPivot().Position - char:GetPivot().Position).Magnitude > Data.MAX_VIEW_DISTANCE then
				playerViewing:set(nil)
			end
		end
		
		local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
		local result: RaycastResult? = workspace:Raycast(ray.Origin, ray.Direction * Data.MAX_VIEW_DISTANCE , raycastParams)
		if not result then
			playerSelected:set(nil)
			return
		end
		local playerHit: Player? = Players:GetPlayerFromCharacter(result.Instance.Parent.Parent)
		if not playerHit or not playerHit:HasTag(PlayerProfiles.Tag) then
			playerSelected:set(nil)
			return
		end
		
		playerSelected:set(playerHit)
	end)
end

return PlayerProfiles