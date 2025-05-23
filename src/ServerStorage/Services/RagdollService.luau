-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Ragdoll = require(ServerStorage.Source.Data.Character.Ragdoll)

local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

local Children = Fusion.Children
local peek = Fusion.peek

-- Service --
local RagdollService = Knit.CreateService {
	Name = "RagdollService",
	Client = {
		RagdollEnabledChanged = Knit.CreateSignal(),
	},
}

-- Types --
type Self = typeof(RagdollService)

-- Constants --
local LIMBS = {
	"Head",
	
	"UpperTorso",
	"LowerTorso",
	
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
	
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	-- R6 = {
	-- 	"Head",
		
	-- 	"Torso",
		
	-- 	"RightArm",
	-- 	"RightLeg",
		
	-- 	"LeftArm",
	-- 	"LeftLeg",
	-- }
}

-- Local --
local charsData: { [Model]: {
	scope: Fusion.Scope,
	enabled: Fusion.Value<boolean>
} } = {}

local resetDebounces: { [Player]: boolean } = {}

local function limbHitbox(scope: Fusion.Scope, limb: Part)
	local collisionPart = scope:New "Part" {
		CFrame = limb:GetPivot(),
		Size = Vector3.one * 0.5,
		
		Anchored = false,
		
		Transparency = 1,
		Material = Enum.Material.Neon,
		Color = Color3.new(1, 0, 0),
	}
	scope:New "WeldConstraint" {
		Part0 = collisionPart,
		Part1 = limb,
		Parent = collisionPart
	}
	return collisionPart
end

function RagdollService.Client:ResetAttempt(player: Player)
	self.Server:ResetAttempt(player)
end

function RagdollService:ResetAttempt(player: Player)
	if resetDebounces[player] then
		return
	end
	resetDebounces[player] = true
	
	task.delay(0.1, function()
		if not player then
			return
		end
		player:LoadCharacter()
		
		resetDebounces[player] = false
	end)
end

function RagdollService.Client:SetRagdollEnabledAttempt(player: Player, enabled: boolean)
	return self.Server:SetRagdollEnabledAttempt(player, enabled)
end

function RagdollService:SetRagdollEnabledAttempt(player: Player, enabled: boolean)
	local char = player.Character
	if not char  then
		return
	end
	
	-- local charData = charsData[char]
	-- if charData then
	-- 	charData.enabled:set(enabled)
	-- end
	
	-- self.Client.RagdollEnabledChanged:Fire(Players:GetPlayerFromCharacter(char), enabled)
	
	return true
end

local function manageRagdollContainers(scope: Fusion.Scope, tempScope: Fusion.Scope, enabled: Fusion.Value<boolean>, char: Model)
	local motor6Ds: { [number]: { limb: Part, motor6D: Motor6D } } = {}
	for _, limbName in LIMBS do
		local limb: Part = char:FindFirstChild(limbName)
		for _, motor6D: Motor6D? in limb:GetChildren() do
			if not motor6D:IsA("Motor6D") or motor6D.Parent.Name == "LowerTorso" then
				continue
			end
			table.insert(motor6Ds, {
				limb = limb,
				motor6D = motor6D,
			})
		end
	end
	
	scope:Observer(enabled):onBind(function()
		local isEnabled = peek(enabled)
		
		local root = char.PrimaryPart
		local lowerTorso = char.LowerTorso
		if root then
			root.Massless = not enabled
			root.CanCollide = not enabled
			
			if lowerTorso and isEnabled then
				tempScope:New "WeldConstraint" {
					Name = "RagdollRootAnchor",
					Parent = lowerTorso,
					Part0 = lowerTorso,
					Part1 = root,
				}
			end
		end
		
		if isEnabled then
			tempScope:New "Folder" {
				Name = "Ragdoll",
				Parent = char,
				[Children] = {
					tempScope:New "Folder" {
						Name = "LimbCollisions",
						[Children] = {
							tempScope:ForValues(LIMBS, function(_use: Fusion.Use, collisionScope: Fusion.Scope, limbName: string)
								local limb: Part = char:FindFirstChild(limbName)
								return limbHitbox(collisionScope, limb)
							end)
						}
					},
					tempScope:New "Folder" {
						Name = "Welds",
						[Children] = {
							tempScope:ForPairs(Ragdoll.SocketData, function(_, weldScope: Fusion.Scope, weldName: string, weldData: {
								A0: string,
								A1: string,
								
								UpperAngle: number?,
								TwistLowerAngle: number?,
								TwistUpperAngle: number?,
							})
								local attachments = {
									[0] = char,
									[1] = char,
								}
								for i=0, 1 do
									for _, childName in string.split(weldData["A"..i], "/") do
										local parent = attachments[i]
										parent = parent:FindFirstChild(childName)
										attachments[i] = parent
									end
								end
								
								local defaults = Ragdoll.Defaults.BallSocketConstrains
								
								return weldScope:New "BallSocketConstraint" {
									Name = weldName,
									
									Attachment0 = attachments[0],
									Attachment1 = attachments[1],
									
									LimitsEnabled = true,
									UpperAngle = weldData.UpperAngle or defaults.UpperAngle,
									
									TwistLimitsEnabled = weldData.TwistLowerAngl ~= nil or weldData.TwistUpperAngle ~= nil,
									TwistLowerAngle = weldData.TwistLowerAngle,
									TwistUpperAngle = weldData.TwistUpperAngle,
									
									Parent = attachments[0].Parent,
								}
							end)
						}
					},
				}
			}
		else
			if root:IsDescendantOf(workspace) then
				root:SetNetworkOwner(nil)
			end
		end
	end)
	
	return motor6Ds
end

local function onCharacterAdded(char: Model)
	local scope: Fusion.Scope = Fusion:scoped()
	local enabled: Fusion.Value<boolean> = scope:Value(false)
	
	charsData[char] = {
		scope = scope,
		enabled = enabled,
	}
	
	local tempScope: Fusion.Scope = Fusion:scoped()
	table.insert(scope, tempScope)
	
	local motor6Ds = manageRagdollContainers(scope, tempScope, enabled, char)
	
	scope:Observer(enabled):onChange(function()
		if peek(enabled) then
			return
		end
		tempScope:doCleanup()
	end)
	
	scope:Observer(enabled):onBind(function()
		local isEnabled = peek(enabled)
		
		local player = Players:GetPlayerFromCharacter(char)
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if char.PrimaryPart then
			table.insert(tempScope, char.PrimaryPart.AncestryChanged:Connect(function(_, parent)
				if not parent then -- If the root part is removed, respawn
					RagdollService:ResetAttempt(player)
				end
			end))
		end
		
		hum.BreakJointsOnDeath = not isEnabled
		hum.RequiresNeck = not isEnabled
		hum.AutoRotate = not isEnabled
		
		hum.PlatformStand = isEnabled
		
		for _, data in motor6Ds do
			data.motor6D.Enabled = not isEnabled
		end
		char.Head.Neck.Enabled = not isEnabled
		
		if not isEnabled then
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			--char.PrimaryPart.Orientation = Vector3.new(0,char.PrimaryPart.Orientation.Y,0)
			--char.PrimaryPart:PivotTo(char:GetPivot() * CFrame.Angles(char.HumanoidRootPart.Orientation.Y))
			tempScope:doCleanup()
		end
	end)
end

function RagdollService:KnitInit()
	-- Players.PlayerAdded:Connect(function(player)
	-- 	resetDebounces[player] = false
		
	-- 	player.CharacterAdded:Connect(onCharacterAdded)
	-- 	if player.Character then
	-- 		onCharacterAdded(player.Character)
	-- 	end
	-- end)
	-- Players.PlayerRemoving:Connect(function(player)
	-- 	resetDebounces[player] = nil
	-- end)
end

return RagdollService