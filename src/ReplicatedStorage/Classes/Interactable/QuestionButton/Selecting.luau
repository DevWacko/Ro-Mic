local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Knit = require(ReplicatedStorage.Packages.Knit)

local OnEvent = Fusion.OnEvent

local function Selecting(self)
	local Packet = Knit.Utils.Packet
	local SetSelectingPacket = Packet("QB_SetSelecting", Packet.Boolean8)
	local SelectQuestionsType = Packet("QB_SelectQuestionsType", Packet.String)
	
	if self.IsServer then
		local playersSelecting = {}
		self.Trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
			local i = table.find(playersSelecting, player.Name)
			if i then
				table.remove(playersSelecting, i)
			end
		end))
		self.Trove:Add(self.Model.PrimaryPart:FindFirstChildWhichIsA("ProximityPrompt").Triggered:Connect(function(player: Player)
			SetSelectingPacket:FireClient(player, true)
			table.insert(playersSelecting, player.Name)
		end))
		self.Trove:Add(SelectQuestionsType.OnServerEvent:Connect(function(player: Player, questionsType: string)
			local char = player.Character
			if not char then
				return false
			end
			if (char:GetPivot().Position - self.Model:GetPivot().Position).Magnitude > self.Data.MAX_CHARACTER_INTERACT_DISTANCE then
				return false
			end
			assert(self.Data.Questions[questionsType], questionsType .. " was not found as a question type")
			
			self.QuestionsType = questionsType
			
			SelectQuestionsType:Fire(questionsType)
			
			return true
		end))
		
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
		local menu: ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(self.Data.MENU_NAME)
		local mainFrame: Frame = menu:FindFirstChild("Main")
		local contents: ScrollingFrame = mainFrame:FindFirstChild("Contents")
		
		local selectedButton: Fusion.Value<GuiButton?> = self.Scope:Value(contents:FindFirstChild(self.Data.START_QUESTION_TYPE))
		
		self.Trove:Add(SetSelectingPacket.OnClientEvent:Connect(function(selecting: boolean)
			if selecting then
				self.MenuController:OpenMenu(self.Data.MENU_NAME)
			else
				self.MenuController:CloseMenu(self.Data.MENU_NAME)
			end
		end))
		self.Trove:Add(SelectQuestionsType.OnClientEvent:Connect(function(questionsType: string)
			selectedButton:set(contents:FindFirstChild(questionsType))
		end))
		
		local function manageButton(button: GuiButton)
			self.Scope:Hydrate(button) {
				BackgroundColor3 = self.Scope:Tween(self.Scope:Computed(function(use: Fusion.Use)
					return use(selectedButton) == button and self.Data.BUTTON_SELECTED_COLOR or self.Data.BUTTON_COLOR
				end), TweenInfo.new(0.2)),
				[OnEvent("MouseButton1Click")] = function()
					if SelectQuestionsType:Fire(button.Name) then
						selectedButton:set(button)
					end
				end,
			}
		end
		for _, button: GuiButton? in contents:GetChildren() do
			if not button:IsA("GuiButton") then
				continue
			end
			manageButton(button)
		end
		
		local size: Fusion.Value<Udim2> = self.Scope:Value(UDim2.new())
		local sizeSpring: Fusion.Spring = self.Scope:Spring(size, self.Data.SPRING_SPEED, self.Data.SPRING_RESPONSIVENESS)
		self.Trove:Add(Streamable.new(self.Model, "Button"):Observe(function(button: BasePart, buttonTrove)
			buttonTrove:Add(Streamable.new(button, "QuestionType"):Observe(function(questionTypeBoard: BillboardGui)
				size:set(questionTypeBoard.Size)
				self.Scope:Hydrate(questionTypeBoard:FindFirstChildWhichIsA("TextLabel")) {
					Size = sizeSpring,
					Text = self.Scope:Computed(function(use: Fusion.Use)
						return `( {use(selectedButton).Name} )`
					end),
				}
			end))
		end))
		self.Scope:Observer(selectedButton):onBind(function()
			sizeSpring:addVelocity(self.Data.ADDED_SIZE)
		end)
	end
end

return Selecting