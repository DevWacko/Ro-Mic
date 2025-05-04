local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZonePlus = require(ReplicatedStorage.Packages.ZonePlus)

local Data = require(ReplicatedStorage.Source.Data.Interacting.GlassBridge)

local function Zones(self)
	local glassZone = self.Trove:Add(ZonePlus.new(self.Model:FindFirstChild("GlassZone")))
	glassZone.playerEntered:Connect(function(player: Player)
		table.insert(self.PlayersInZone, player.Name)
	end)
	glassZone.playerExited:Connect(function(player: Player)
		local i = table.find(self.PlayersInZone, player.Name)
		if i then
			table.remove(self.PlayersInZone, i)
		end
	end)
	
	self.Trove:Add(self.Model:FindFirstChild("RespawnTouch").Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local char = player.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then
			return
		end
		
		if Data.STUN_PLAYER then
			hum.EvaluateStateMachine = true
		end
		char:PivotTo(self.Model.GlassSpawn.CFrame * CFrame.new(0, Data.RESPAWN_HEIGHT, 0))
		char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
		char.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end))
end

return Zones