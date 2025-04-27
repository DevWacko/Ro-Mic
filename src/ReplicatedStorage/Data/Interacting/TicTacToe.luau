local TicTacToe = {}

TicTacToe.PLAYER_KICK_DISTANCE = 20

TicTacToe.PLAYERS_REQUIRED = 2
TicTacToe.MAX_PLAYERS = 2

TicTacToe.GAME_COOLDOWN = 3

TicTacToe.PLAYER_SYMBOLS = { "X", "O" }
TicTacToe.STARTER_PLAYER_INDEX = 1

TicTacToe.LINE_PART_PROPERTIES = {
	Anchored = true,
	CanCollide = false,
	BrickColor = BrickColor.Red(),
}

TicTacToe.SYMBOL_HOVER_HEIGHT = 1
TicTacToe.SYMBOL_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)

TicTacToe.COLUMNS = 3
TicTacToe.ROWS = 3

TicTacToe.SLOT_CLICK_DETECTOR_ACTIVATION_DISTANCE = 20

return TicTacToe