local QuestionButton = {}
QuestionButton.__index = QuestionButton

export type self = typeof(QuestionButton)

function QuestionButton.new()
	local self = setmetatable({}, QuestionButton)
	return self
end

function QuestionButton:Destroy()
	
end

return QuestionButton
