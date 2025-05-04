local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Source.Data.Interacting.GlassBridge)

local function Resetting(self)
	local resetButtonPart: Part = self.Model.ResetStand.PrimaryPart
	local resetCd: ClickDetector = resetButtonPart:FindFirstChild("Reset")
	local startActicationDistance = resetCd.MaxActivationDistance
	
	local resetLabel = resetButtonPart:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
	
	local function startCountdown()
		local secondsLeft = Data.RESET_COOLDOWN
		local startText = resetLabel.Text
		while secondsLeft >= 0 do
			resetLabel.Text = secondsLeft .. "s"
			secondsLeft -= 1
			task.wait(1)
		end
		resetLabel.Text = startText
	end
	
	self.Trove:Add(resetCd.MouseClick:Connect(function()
		if #self.PlayersInZone > 0 then
			return
		end
		task.spawn(startCountdown)
		
		resetCd.MaxActivationDistance = 0
		task.delay(Data.RESET_COOLDOWN, function()
			resetCd.MaxActivationDistance = startActicationDistance
		end)
		
		self:GenerateNewPath()
	end))
end

return Resetting