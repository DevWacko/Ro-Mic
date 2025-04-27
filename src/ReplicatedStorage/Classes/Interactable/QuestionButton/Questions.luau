local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Knit = require(ReplicatedStorage.Packages.Knit)

local function Questions(self)
	local Packet = Knit.Utils.Packet
	local ChangeQuestionPacket = Packet("QB_ChangeQuestion")
	local SetQuestionPacket = Packet("QB_SetQuestion", Packet.String)
	
	if self.IsServer then
		local currentQuestionBlacklists = {}
		for category, _ in self.Data.Questions do
			currentQuestionBlacklists[category] = {}
		end
		
		local cd: ClickDetector = self.Model:FindFirstChild("Button"):FindFirstChild("Change")
		local startActicationDistance = cd.MaxActivationDistance
		self.Trove:Add(ChangeQuestionPacket.OnServerEvent:Connect(function(player: Player)
			local char = player.Character
			if not char then
				return
			end
			if (char:GetPivot().Position - self.Model:GetPivot().Position).Magnitude > self.Data.MAX_CHARACTER_INTERACT_DISTANCE then
				return
			end
			
			cd.MaxActivationDistance = 0
			task.delay(self.Data.QUESTION_COOLDOWN, function()
				cd.MaxActivationDistance = startActicationDistance
			end)
			
			local questions = self.Data.Questions[self.QuestionsType]
			
			local questionPicked: string
			repeat
				questionPicked = questions[math.random(1, #questions)]
				task.wait()
			until questionPicked and not table.find(currentQuestionBlacklists[self.QuestionsType], questionPicked)
			table.insert(currentQuestionBlacklists[self.QuestionsType], questionPicked)
			
			if #currentQuestionBlacklists[self.QuestionsType] == #questions then
				currentQuestionBlacklists[self.QuestionsType] = {}
			end
			
			SetQuestionPacket:Fire(questionPicked)
		end))
	elseif self.IsClient then
		local hl: Highlight?
		local function setSelected(selected: boolean)
			if hl then
				hl:Destroy()
			end
			if selected then
				hl = Instance.new("Highlight")
				for key, value in self.Data.HIGHLIGHT_PROPERTIES do
					hl[key] = value
				end
				hl.Parent = self.Model
			end
		end
		Streamable.new(self.Model, "Button"):Observe(function(button: Part, buttonTrove)
			buttonTrove:Add(Streamable.new(button, "Change"):Observe(function(cd: ClickDetector, cdTrove)
				cdTrove:Add(cd.MouseHoverEnter:Connect(function(player: Player)
					if player ~= self.LocalPlayer then
						return
					end
					setSelected(true)
				end))
				cdTrove:Add(cd.MouseHoverLeave:Connect(function(player: Player)
					if player ~= self.LocalPlayer then
						return
					end
					setSelected(false)
				end))
				cdTrove:Add(cd.MouseClick:Connect(function(player: Player)
					if player ~= self.LocalPlayer then
						return
					end
					ChangeQuestionPacket:Fire()
				end))
			end))
		end)
	end
end

return Questions