-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages --
local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):FindFirstChild("Fusion"))

-- Main Module --
local AnimationButton = {
	Tag = "AnimationButton"
}

-- Local --
local tempScopes: { [GuiButton]: Fusion.Scope } = {}

local tracks: { AnimationTrack } = {}

local player = Players.LocalPlayer

AnimationButton.taggedObjectAdded = function(taggedObject: GuiButton)
	local scope = Fusion:scoped()
	
	local animation: Animation = taggedObject:FindFirstChildWhichIsA("Animation")
	
	local animator: Animator?
	local track: AnimationTrack?
	local function charAdded(char: Model)
		local hum = char:WaitForChild("Humanoid")
		if hum then
			animator = hum:FindFirstChildWhichIsA("Animator")
			track = animator:LoadAnimation(animation)
			track.Looped = taggedObject:GetAttribute("Loop")
			table.insert(tracks, track)
		end
	end
	table.insert(scope, player.CharacterAdded:Connect(charAdded))
	if player.Character then
		charAdded(player.Character)
	end
	
	table.insert(scope, taggedObject.MouseButton1Click:Connect(function()
		if animator == nil or track == nil then return end
		if not track.IsPlaying then
			for _, oldTrack in tracks do
				oldTrack:Stop()
			end
			track:Play()
		elseif track.IsPlaying then
			track:Stop()
		end
	end))
	
	tempScopes[taggedObject] = scope
end

AnimationButton.taggedObjectRemoved = function(taggedObject: GuiButton)
	local scope = tempScopes[taggedObject]
	if scope then
		scope:doCleanup()
		tempScopes[taggedObject] = nil
	end
end

return AnimationButton