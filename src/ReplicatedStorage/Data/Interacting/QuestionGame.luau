local QuestionGame = {}

QuestionGame.MENU_NAME = "QuestionType"

QuestionGame.QUESTION_COOLDOWN = 2.2

QuestionGame.Questions = {
	["All"] = {
		"Some question in all category",
		"Some other question in all category",
	},
	["General"] = {
		"Some question in general category",
		"Some other question in general category",
	},
}

QuestionGame.START_QUESTION_TYPE = "All"

QuestionGame.HIGHLIGHT_PROPERTIES = {
	DepthMode = Enum.HighlightDepthMode.Occluded,
}

QuestionGame.BUTTON_SELECTED_COLOR = Color3.fromRGB(215, 224, 244)
QuestionGame.BUTTON_COLOR = Color3.new(1, 1, 1)

QuestionGame.SPRING_SPEED = 15
QuestionGame.SPRING_RESPONSIVENESS = 0.2
QuestionGame.ADDED_SIZE = UDim2.fromOffset(10, 10)

QuestionGame.MAX_CHARACTER_INTERACT_DISTANCE = 30

return QuestionGame