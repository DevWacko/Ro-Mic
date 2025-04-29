local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Knit = require(ReplicatedStorage.Packages.Knit)

local OnEvent = Fusion.OnEvent

local Packets = require(ReplicatedStorage.Source.Data.Packets)

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
			Packets.SetSelectingPacket:FireClient(player, self.Id, true)
			table.insert(playersSelecting, player.Name)
		end))
		self.Trove:Add(Packets.SelectQuestionsTypePacket.OnServerEvent:Connect(function(player: Player, id: string, questionsType: string)
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
			
			Packets.SelectQuestionsTypePacket:Fire(self.Id, questionsType)
			
			return true
		end))
		Packets.GetQuestionsTypePacket.OnServerInvoke = function()
			return self.QuestionsType
		end
		
		self.Trove:Add(task.spawn(function()
			while task.wait(1) do
				for _, playerName in playersSelecting do
					local player: Player? = Players:FindFirstChild(playerName)
					if not player then
						continue
					end
					local char = player.Character
					if not char then
						continue
					end
					if (char:GetPivot().Position - self.Model:GetPivot().Position).Magnitude > self.Data.MAX_CHARACTER_INTERACT_DISTANCE then
						SetSelectingPacket:FireClient(player, false)
					end
				end
			end
		end))
		
		local questionTypeBoard: BillboardGui = ReplicatedStorage.Assets.Gui.Billboards.QuestionButton.QuestionType:Clone()
		questionTypeBoard.Parent = self.Model:FindFirstChild("Button")
	elseif self.IsClient then
		-- local menu: ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(self.Data.MENU_NAME)
		-- local mainFrame: Frame = menu:FindFirstChild("Main")
		-- local contents: ScrollingFrame = mainFrame:FindFirstChild("Contents")
		
		self.QuestionsType:set(GetQuestionsType:Fire())
		
		self.Trove:Add(SetSelectingPacket.OnClientEvent:Connect(function(selecting: boolean)
			if selecting then
				self.MenuController:OpenMenu(self.Data.MENU_NAME, self, GetQuestionsType:Fire())
			else
				self.MenuController:CloseMenu(self.Data.MENU_NAME)
			end
		end))
		
		local size: Fusion.Value<Udim2> = self.Scope:Value(UDim2.new())
		local sizeSpring: Fusion.Spring = self.Scope:Spring(size, self.Data.SPRING_SPEED, self.Data.SPRING_RESPONSIVENESS)
		
		self.SelectQuestionsType.OnClientEvent:Connect(function(newQuestionsType: string)
			self.QuestionsType:set(newQuestionsType)
			self.MenuController:CallMenuFunction(self.Data.MENU_NAME, "setQuestionsType", newQuestionsType)
		end)
		self.Trove:Add(Streamable.new(self.Model, "Button"):Observe(function(button: BasePart, buttonTrove)
			buttonTrove:Add(Streamable.new(button, "QuestionType"):Observe(function(questionTypeBoard: BillboardGui)
				size:set(questionTypeBoard.Size)
				self.Scope:Hydrate(questionTypeBoard:FindFirstChildWhichIsA("TextLabel")) {
					Size = sizeSpring,
					Text = self.Scope:Computed(function(use: Fusion.Use)
						return `( {use(self.QuestionsType)} )`
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