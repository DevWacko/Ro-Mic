local MessageBoards = {}

MessageBoards.MAX_MESSAGES_PER_PLAYER = 3

MessageBoards.Gui = {
	Message = {
		MAX_CHARACTERS = 200,
		
		TWEEN_INFO = TweenInfo.new(0.1),
		COLOR_TWEEN_INFO = TweenInfo.new(0.5),
		
		CANNOT_WRITE_COLOR = Color3.new(1, 0.32549, 0.337255), 
		CAN_WRITE_COLOR = Color3.new(0.32549, 1, 0.392157),
		MESSAGE_BG_COLOR = Color3.fromRGB(240, 240, 240),
		
		CORNER_RADIUS = UDim.new(0, 0),
		
		ROTATION_RANGE_MIN = -3,
		ROTATION_RANGE_MAX = 3,
		
		FONT = Enum.Font.Nunito,
		FONT_SIZE = 25,
	}
}

return MessageBoards