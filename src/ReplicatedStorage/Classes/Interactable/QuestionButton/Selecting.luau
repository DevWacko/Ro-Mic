local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Packets = require(ReplicatedStorage.Source.Data.Packets).QuestionButton

local function Selecting(self)
	if self.IsServer then
		local playersSelecting = {}
		self.Trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
			local i = table.find(playersSelecting, player.Name)
			if i then
				table.remove(playersSelecting, i)
			end
		end))
		self.Trove:Add(self.Model.PrimaryPart:FindFirstChildWhichIsA("ProximityPrompt").Triggered:Connect(function(player: Player)
			Packets.SetSelecting:FireClient(player, self.Id, true)
			table.insert(playersSelecting, player.Name)
		end))
		self.Trove:Add(Packets.SelectQuestionsType.OnServerEvent:Connect(function(player: Player, id: string, questionsType: string)
			if id ~= self.Id then
				return
			end
			
			if not table.find(playersSelecting, player.Name) then
				return
			end
			
			local char = player.Character
			if not char then
				return false
			end
			if (char:GetPivot().Position - self.Model:GetPivot().Position).Magnitude > self.Data.MAX_CHARACTER_INTERACT_DISTANCE then
				return false
			end
			assert(self.Data.Questions[questionsType], questionsType .. " was not found as a question type")
			
			self.QuestionsType = questionsType
			self.Model:SetAttribute("QuestionsType", questionsType)
			
			Packets.SelectQuestionsType:Fire(self.Id, questionsType)
			
			return true
		end))
		
		self.Trove:Add(task.spawn(function()
			while task.wait(1) do
				for i, playerName in playersSelecting do
					local player: Player? = Players:FindFirstChild(playerName)
					if not player then
						continue
					end
					local char = player.Character
					if not char then
						continue
					end
					if (char:GetPivot().Position - self.Model:GetPivot().Position).Magnitude > self.Data.MAX_CHARACTER_INTERACT_DISTANCE then
						table.remove(playersSelecting, i)
						Packets.SetSelecting:FireClient(player, self.Id, false)
					end
				end
			end
		end))
		
		local questionTypeBoard: BillboardGui = ReplicatedStorage.Assets.Gui.Billboards.QuestionButton.QuestionType:Clone()
		questionTypeBoard.Parent = self.Model:FindFirstChild("Button")
	elseif self.IsClient then
		self.QuestionsType:set(self.Model:GetAttribute("QuestionsType"))
		
		self.Trove:Add(Packets.SetSelecting.OnClientEvent:Connect(function(id: string, selecting: boolean)
			if id ~= self.Id then
				return
			end
			
			if selecting then
				self.MenuController:OpenMenu(self.Data.MENU_NAME, self, self.Model:GetAttribute("QuestionsType"))
			else
				self.MenuController:CloseMenu(self.Data.MENU_NAME)
			end
		end))
		
		local size: Fusion.Value<Udim2> = self.Scope:Value(UDim2.new())
		local sizeSpring: Fusion.Spring = self.Scope:Spring(size, self.Data.SPRING_SPEED, self.Data.SPRING_RESPONSIVENESS)
		local questionLabelStartSize: UDim2?
		
		Packets.SelectQuestionsType.OnClientEvent:Connect(function(id: string, newQuestionsType: string)
			if id ~= self.Id then
				return
			end
			
			self.QuestionsType:set(newQuestionsType)
			self.MenuController:CallMenuFunction(self.Data.MENU_NAME, "setQuestionsType", newQuestionsType)
		end)
		self.Trove:Add(Streamable.new(self.Model, "Button"):Observe(function(button: BasePart, buttonTrove)
			buttonTrove:Add(Streamable.new(button, "QuestionType"):Observe(function(questionTypeBoard: BillboardGui)
				local label: TextLabel = questionTypeBoard:FindFirstChildWhichIsA("TextLabel")
				if not questionLabelStartSize then
					questionLabelStartSize = label.Size
				end
				size:set(questionLabelStartSize)
				self.Scope:Hydrate(label) {
					Size = sizeSpring,
					Text = self.Scope:Computed(function(use: Fusion.Use)
						return `({use(self.QuestionsType)} Questions)`
					end),
				}
			end))
		end))
		self.Scope:Observer(self.QuestionsType):onBind(function()
			sizeSpring:addVelocity(self.Data.ADDED_SIZE)
		end)
	end
end

return Selecting