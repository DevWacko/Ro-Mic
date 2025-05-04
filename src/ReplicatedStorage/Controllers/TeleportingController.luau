local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Knit = require(ReplicatedStorage.Packages.Knit)

local scoped, peek = Fusion.scoped, Fusion.peek

local TeleportingController = Knit.CreateController { Name = "TeleportingController" }

function TeleportingController:KnitStart()
	
end

function TeleportingController:KnitInit()
	local TeleportingService = Knit.GetService("TeleportingService")
	
	local scope = scoped(Fusion)
	local teleporting = scope:Value(false)
	
	local savedGuiEnabled = {}
	
	TeleportingService.Teleporting:Connect(function(isTeleporting: boolean)
		teleporting:set(isTeleporting)
	end)
	
	scope:New "BlurEffect" {
		Name = "TeleportBlur",
		Parent = game.Lighting,
		Size = scope:Tween(scope:Computed(function(use)
			return use(teleporting) and 50 or 0
		end), TweenInfo.new(1))
	}
	
	local teleportingGui: ScreenGui = Players.LocalPlayer.PlayerGui:WaitForChild("Teleporting")
	local canvas: CanvasGroup = teleportingGui:WaitForChild("CanvasGroup")
	local loadingLabel: TextLabel = canvas:WaitForChild("Label")
	local startLabelText = loadingLabel.Text
	
	local labelLoop = false
	scope:Observer(teleporting):onBind(function()
		local isTeleporting = peek(teleporting) == true
		if isTeleporting then
			for _, gui: ScreenGui? in Players.LocalPlayer.PlayerGui:GetChildren() do
				if gui:IsA("ScreenGui") then
					savedGuiEnabled[gui] = gui.Enabled
					gui.Enabled = false
				end
			end
			task.spawn(function()
				labelLoop = true
				while labelLoop do
					for i=1, 3 do
						loadingLabel.Text = startLabelText
						for _=1, i do
							loadingLabel.Text = loadingLabel.Text .. "."
						end
						task.wait(0.5)
					end
				end
			end)
		else
			labelLoop = false
			for gui: ScreenGui, enabled: boolean in savedGuiEnabled do
				gui.Enabled = enabled
			end
			savedGuiEnabled = {}
		end
		teleportingGui.Enabled = isTeleporting
		labelLoop = isTeleporting
		counter = 0
	end)
	scope:Hydrate(canvas) {
		GroupTransparency = scope:Tween(scope:Computed(function(use)
			return use(teleporting) and 0 or 1
		end), TweenInfo.new(1))
	}
end

return TeleportingController