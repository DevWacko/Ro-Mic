local MessageBoards = {}

MessageBoards.Gui = {
	Message = {
		TWEEN_INFO = TweenInfo.new(0.1),
		COLOR_TWEEN_INFO = TweenInfo.new(0.5),
		
		CANNOT_WRITE_COLOR = Color3.new(1, 0, 0.4),
		CAN_WRITE_COLOR = Color3.new(0, 1, 0.46),
		MESSAGE_BG_COLOR = Color3.new(0.9, 0.9, 0.9),
		
		CORNER_RADIUS = UDim.new(0, 10),
		
		FONT = Enum.Font.BuilderSans,
		FONT_SIZE = 14,
	}
}

return MessageBoards