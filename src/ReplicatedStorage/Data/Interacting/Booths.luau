local Booths = {}

Booths.Defaults = {
	OWNER_LABEL = "unowned",
	DESCRIPTION_DATA = {
		text = "Your text here",
		textColor = Color3.new(1, 1, 1), strokeColor = Color3.new(0, 0, 0),
		font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold), strokeThickness = 0.6,
	}
}

Booths.PlayerThumbnail = {
	TYPE = Enum.ThumbnailType.HeadShot,
	SIZE = Enum.ThumbnailSize.Size420x420,
}

return Booths