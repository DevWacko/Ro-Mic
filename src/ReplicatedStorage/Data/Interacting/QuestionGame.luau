local QuestionGame = {}

QuestionGame.MENU_NAME = "QuestionType"

QuestionGame.QUESTION_COOLDOWN = 2.2
QuestionGame.QUESTION_SHOW_DELAY = 1

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
QuestionGame.QUESTION_HIDE_STUDS_OFFSET = Vector3.yAxis * 2

QuestionGame.HIGHLIGHT_PROPERTIES = {
	FillColor = Color3.new(1, 1, 1),
	DepthMode = Enum.HighlightDepthMode.Occluded,
}

QuestionGame.BUTTON_SELECTED_COLOR = Color3.fromRGB(215, 224, 244)
QuestionGame.BUTTON_COLOR = Color3.new(1, 1, 1)

QuestionGame.SPRING_SPEED = 20
QuestionGame.SPRING_RESPONSIVENESS = 0.5
QuestionGame.ADDED_SIZE = UDim2.fromOffset(10, 10)

QuestionGame.TWEEN_INFO = TweenInfo.new(0.25)

QuestionGame.MAX_CHARACTER_INTERACT_DISTANCE = 30

return QuestionGame