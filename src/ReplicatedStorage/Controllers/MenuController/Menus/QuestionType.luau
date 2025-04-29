local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Knit = require(ReplicatedStorage.Packages.Knit)

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local Packets = require(ReplicatedStorage.Source.Data.Packets).QuestionButton

local QuestionType = { MenuName = "QuestionType" }

local scope: Fusion.Scope = Fusion:scoped()
local questionsType: Fusion.Value<string> = scope:Value("")

local currentClass

QuestionType.shown = function(class, loadedQuestionsType: string)
	currentClass = class
	questionsType:set(loadedQuestionsType)
end

QuestionType.hidden = function()
	currentClass = nil
	questionsType:set("")
end

QuestionType.setQuestionsType = function(newQuestionsType: string)
	questionsType:set(newQuestionsType)
end

QuestionType.menuLoaded = function(menu: ScreenGui)
	local data = Knit.Data.Interacting.QuestionGame
	
	local mainFrame: Frame = menu:FindFirstChild("Main")
	local contents: ScrollingFrame = mainFrame:FindFirstChild("Contents")
	
	local selectedButton: Fusion.Value<GuiButton?> = scope:Value(nil)
	scope:Observer(questionsType):onBind(function()
		if peek(questionsType) == "" then
			return
		end
		selectedButton:set(contents:WaitForChild(peek(questionsType)))
	end)
	
	local function manageButton(button: GuiButton)
		scope:Hydrate(button) {
			BackgroundColor3 = scope:Tween(scope:Computed(function(use: Fusion.Use)
				return use(selectedButton) == button and data.BUTTON_SELECTED_COLOR or data.BUTTON_COLOR
			end), TweenInfo.new(0.2)),
			[OnEvent("MouseButton1Click")] = function()
				if not currentClass then
					return
				end
				Packets.SelectQuestionsType:Fire(currentClass.Id, button.Name)
			end,
		}
	end
	for _, button: GuiButton? in contents:GetChildren() do
		if not button:IsA("GuiButton") then
			continue
		end
		manageButton(button)
	end
end

return QuestionType