local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local Data = require(ReplicatedStorage.Source.Data.Interacting.GlassBridge)

local function Jumps(self)
	local jumpsTrove: Trove.Trove = self.Trove:Add(Trove.new())
	local jumpsLastSpawn: { [Part]: number } = {}
	
	task.spawn(function()
		while task.wait(1) do
			for platform, lastSpawn in jumpsLastSpawn do
				if tick() - lastSpawn < Data.PLATFORM_RESPAWN_COOLDOWN then
					continue
				end
				platform.Transparency = 0
				platform.CanCollide = true
				jumpsLastSpawn[platform] = tick()
			end
		end
	end)
	
	self.Trove:Add(self.PathReset:Connect(function()
		jumpsTrove:Clean()
		
		for _, model in self.Model.Jumps:GetChildren() do
			for _, p in model:GetChildren() do
				p.Transparency = 0
				p.CanCollide = true
				jumpsLastSpawn[p] = tick()
			end
		end
		
		for _, fakeJumps in self.Path do
			for _, fakeJumpPart: Part in fakeJumps do
				jumpsTrove:Add(fakeJumpPart.Touched:Connect(function(hit)
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
						hum.EvaluateStateMachine = false
						task.delay(Data.STUNNED_DURATION, function()
							if hum then
								hum.EvaluateStateMachine = true
							end
						end)
					end
					
					local function rndAxis()
						return math.random(Data.PLATFORM_ROTATE_FORCE_MIN, Data.PLATFORM_ROTATE_FORCE_MAX)
					end
					
					local clone = fakeJumpPart:Clone()
					clone.Parent = workspace
					clone.Anchored = false
					clone.AssemblyAngularVelocity = Vector3.new(rndAxis(), rndAxis(), rndAxis())
					
					fakeJumpPart.Transparency = 1
					fakeJumpPart.CanCollide = false
					
					self.LocalTweenService:Tween(clone, Data.TWEEN_INFO, {
						Transparency = 1,
					})
					Debris:AddItem(clone, Data.TWEEN_INFO.Time)
				end))
			end
		end
	end))
end

return Jumps