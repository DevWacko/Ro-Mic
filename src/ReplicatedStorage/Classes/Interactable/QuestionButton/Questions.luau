local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Signal = require(ReplicatedStorage.Packages.Signal)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Packets = require(ReplicatedStorage.Source.Data.Packets).QuestionButton
local Sound = require(ReplicatedStorage.Source.Classes.Sound)

local peek = Fusion.peek

local function Questions(self)
	if self.IsServer then
		local lastQuestion = ""
		local currentQuestionBlacklists = {}
		for category, _ in self.Data.Questions do
			currentQuestionBlacklists[category] = {}
		end
		
		local cd: ClickDetector = self.Model:FindFirstChild("Button"):FindFirstChild("Change")
		local startActicationDistance = cd.MaxActivationDistance
		self.Trove:Add(Packets.ChangeQuestion.OnServerEvent:Connect(function(player: Player, id: string)
			if id ~= self.Id then
				return
			end
			
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
			until questionPicked and
				not table.find(currentQuestionBlacklists[self.QuestionsType], questionPicked)
				and questions ~= lastQuestion
			table.insert(currentQuestionBlacklists[self.QuestionsType], questionPicked)
			
			if #currentQuestionBlacklists[self.QuestionsType] == #questions then
				currentQuestionBlacklists[self.QuestionsType] = {}
			end
			
			self.Question = questionPicked
			self.Model:SetAttribute("Question", questionPicked)
			
			Packets.SetQuestion:Fire(self.Id, questionPicked)
		end))
	elseif self.IsClient then
		local questionAppeared = self.Trove:Add(Signal.new())
		
		local questionPrompt: BillboardGui = self.Trove:Add(self.Billboards:FindFirstChild("QuestionPrompt"):Clone())
		local questionBoardMain: CanvasGroup = questionPrompt:FindFirstChild("Main")
		local startStudsOffset = questionPrompt.StudsOffset
		
		local questionText: Fusion.Value<string> = self.Scope:Value(self.Model:GetAttribute("Question"))
		local questionShown: Fusion.Value<boolean> = self.Scope:Value(peek(questionText) ~= "")
		self.Scope:Hydrate(questionPrompt) {
			StudsOffset = self.Scope:Spring(self.Scope:Computed(function(use: Fusion.Use)
				return use(questionShown) and startStudsOffset or self.Data.QUESTION_HIDE_STUDS_OFFSET
			end), self.Data.SPRING_SPEED, self.Data.SPRING_RESPONSIVENESS)
		}
		-- self.Scope:Hydrate(questionBoardMain) {
		-- 	GroupTransparency = self.Scope:Tween(self.Scope:Computed(function(use: Fusion.Use)
		-- 		return use(questionShown) and 0 or 1
		-- 	end), self.Data.TWEEN_INFO)
		-- }
		local tTween = self.Scope:Tween(self.Scope:Computed(function(use: Fusion.Use)
			return use(questionShown) and 0 or 1
		end), self.Data.TWEEN_INFO)
		self.Scope:Hydrate(questionBoardMain:FindFirstChild("Question")) {
			Text = questionText,
			TextTransparency = tTween,
			BackgroundTransparency = tTween
		}
		
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
		self.Trove:Add(Streamable.new(self.Model, "Button"):Observe(function(button: Part, buttonTrove)
			questionPrompt.Parent = button
			
			buttonTrove:Add(questionAppeared:Connect(function()
				Sound.new(ReplicatedStorage.Assets.Sounds.Interactables.QuestionButton.QuestionAppear, button):Play()
			end))
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
					Packets.ChangeQuestion:Fire(self.Id)
				end))
			end))
		end))
		self.Trove:Add(Packets.SetQuestion.OnClientEvent:Connect(function(id: string, newQuestion: string)
			if id ~= self.Id then
				return
			end
			
			questionShown:set(false)
			local function set()
				questionText:set(newQuestion)
				questionShown:set(true)
				questionAppeared:Fire()
			end
			if peek(questionText) == "" then
				set()
			else
				task.delay(self.Data.QUESTION_SHOW_DELAY, set)
			end
		end))
	end
end

return Questions