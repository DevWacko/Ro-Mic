local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Signal = require(ReplicatedStorage.Packages.Signal)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Packets = require(ReplicatedStorage.Source.Data.Packets).QuestionButton
local Sound = require(ReplicatedStorage.Source.Classes.Sound)

local peek = Fusion.peek

local Data = require(ReplicatedStorage.Source.Data.Interacting.QuestionGame)

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
			
			Packets.AddQuestion:Fire(self.Id, questionPicked)
		end))
	elseif self.IsClient then
		local questionAppeared = self.Trove:Add(Signal.new())
		
		local questionPrompt: BillboardGui = self.Trove:Add(self.Billboards:FindFirstChild("QuestionPrompt"):Clone())
		local questionBoardMain: CanvasGroup = questionPrompt:FindFirstChild("Main")
		local startStudsOffset = questionPrompt.StudsOffset
		
		local questionText: Fusion.Value<string> = self.Scope:Value(self.Model:GetAttribute("Question"))
		local questionShown: Fusion.Value<boolean> = self.Scope:Value(peek(questionText) ~= "")
		
		local currentQuestions: { [number]: {
			Scope: Fusion.Scope,
			Shown: Fusion.Value<boolean>,
			Created: number,
		} } = {}
		
		--[[ local lastMessageChanged = tick()
		self.Scope:Observer(questionText):onBind(function()
			lastMessageChanged = tick()
		end)
		RunService.Heartbeat:Connect(function()
			if tick() - lastMessageChanged >= Data.QUESTION_AUTO_HIDE_DELAY then
				questionShown:set(false)
			end
		end) ]]
		
		--[[ local tTween = self.Scope:Tween(self.Scope:Computed(function(use: Fusion.Use)
			return use(questionShown) and 0 or 1
		end), self.Data.TWEEN_INFO)
		self.Scope:Hydrate(questionBoardMain:FindFirstChild("Question")) {
			Text = questionText,
			TextTransparency = tTween,
			BackgroundTransparency = tTween
		} ]]
		
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
		
		local function removeQuestion(index: number)
			local data = currentQuestions[index]
			table.remove(currentQuestions, index)
			
			data.Shown:set(false)
			
			task.delay(Data.TWEEN_INFO.Time, function()
				data.Scope:doCleanup()
			end)
		end
		
		self.Trove:Add(Packets.AddQuestion.OnClientEvent:Connect(function(id: string, addedQuestion: string)
			if id ~= self.Id then
				return
			end
			
			if #currentQuestions + 1 > Data.MAX_QUESTIONS then
				removeQuestion(1)
			end
			
			local questionScope = Fusion:scoped()
			table.insert(self.Scope, questionScope)
			
			local shown = questionScope:Value(false)
			
			local label = ReplicatedStorage.Assets.Gui.Templates.Question:Clone()
			label.Text = addedQuestion
			
			local startSize = label.Size
			
			local questionLabel = questionScope:Hydrate(label) {
				Name = "Question" .. #currentQuestions,
				Parent = questionBoardMain,
				
				--[[ Size = questionScope:Spring(questionScope:Computed(function(use)
					return use(shown) and startSize or UDim2.new()
				end), 15, 0.5), ]]
				
				Text = addedQuestion,
				TextTransparency = questionScope:Tween(questionScope:Computed(function(use)
					return use(shown) and 0 or 1
				end), Data.TWEEN_INFO),
				BackgroundTransparency = questionScope:Tween(questionScope:Computed(function(use)
					return use(shown) and 0 or 1
				end), Data.TWEEN_INFO)
			}
			
			shown:set(true)
			
			table.insert(currentQuestions, {
				Scope = questionScope,
				Shown = shown,
				Created = tick(),
			})
			
			questionAppeared:Fire()
		end))
		self.Trove:Add(RunService.Heartbeat:Connect(function()
			for i, data in currentQuestions do
				if tick() - data.Created >= (i == #currentQuestions and Data.MAIN_QUESTION_REMOVE_DELAY or Data.OLD_QUESTION_REMOVE_DELAY) then
					removeQuestion(i)
				end
			end
		end))
	end
end

return Questions