local Booths = {}

Booths.Defaults = {
	OWNER_LABEL = "unowned",
	DESCRIPTION_DATA = {
		text = "Your text here",
		textColor = Color3.new(1, 1, 1), strokeColor = Color3.new(0, 0, 0),
		font = Font.new("rbxasset://fonts/families/BuilderSans.json"), weight = Enum.FontWeight.Regular, style = Enum.FontStyle.Italic,
		strokeOpacity = 0,
	}
}

Booths.BoothStyling = {
	COLORS = {
		[1] = Color3.fromRGB(0, 0, 0),
		[2] = Color3.fromRGB(40, 40, 40),
		[3] = Color3.fromRGB(80, 80, 80),
		[4] = Color3.fromRGB(120, 120, 120),
		[5] = Color3.fromRGB(180, 180, 180),
		[6] = Color3.fromRGB(255, 255, 255),
		[7] = Color3.fromRGB(196, 165, 240),
		[8] = Color3.fromRGB(165, 202, 240),
		[9] = Color3.fromRGB(194, 240, 165),
		[10] = Color3.fromRGB(240, 225, 165),
		[11] = Color3.fromRGB(240, 192, 165),
		[12] = Color3.fromRGB(240, 165, 165),
		[13] = Color3.fromRGB(158, 99, 240),
		[14] = Color3.fromRGB(99, 169, 240),
		[15] = Color3.fromRGB(153, 240, 99),
		[16] = Color3.fromRGB(240, 214, 99),
		[17] = Color3.fromRGB(240, 151, 99),
		[18] = Color3.fromRGB(240, 99, 99),
		[19] = Color3.fromRGB(124, 36, 240),
		[20] = Color3.fromRGB(36, 138, 240),
		[21] = Color3.fromRGB(114, 240, 36),
		[22] = Color3.fromRGB(240, 206, 36),
		[23] = Color3.fromRGB(240, 117, 36),
		[24] = Color3.fromRGB(240, 36, 36),
	},
	FONTS = {
		[1] = Font.fromName("Arimo"),
		[2] = Font.fromName("BuilderExtended"),
		[3] = Font.fromName("BuilderSans"),
		[4] = Font.fromName("ComicNeueAngular"),
		[5] = Font.fromName("DenkOne"),
		[6] = Font.fromName("Guru"),
		[7] = Font.fromName("Inconsolata"),
		[8] = Font.fromName("Jura"),
		[9] = Font.fromName("Michroma"),
		[10] = Font.fromName("Montserrat"),
		[11] = Font.fromName("Oswald"),
		[12] = Font.fromName("Zekton"),
		[13] = Font.fromName("Ubuntu"),
		[14] = Font.fromName("Roboto"),
		[15] = Font.fromName("Sarpanch"),
		[16] = Font.fromName("SourceSansPro"),
		[17] = Font.fromName("TitilliumWeb"),
		[18] = Font.fromName("FredokaOne"),
		[19] = Font.fromName("Fondamento"),
		[20] = Font.fromName("YellowTad"),
		[21] = Font.fromName("HighwayGothic"),
		[22] = Font.fromName("LuckiestGuy"),
		[23] = Font.fromName("PessStart"),
		[24] = Font.fromName("PermanentMarker"),
		[25] = Font.fromName("CaesarDressing"),
	},
	WEIGHTS = {
		[1] = Enum.FontWeight.Regular,
		[2] = Enum.FontWeight.SemiBold,
		[3] = Enum.FontWeight.Bold,
		[4] = Enum.FontWeight.Heavy,
		[5] = Enum.FontWeight.ExtraLight,
		[6] = Enum.FontWeight.Light,
	},
	STYLES = {
		[1] = Enum.FontStyle.Normal,
		[2] = Enum.FontStyle.Italic,
	},
}

Booths.PlayerThumbnail = {
	TYPE = Enum.ThumbnailType.HeadShot,
	SIZE = Enum.ThumbnailSize.Size420x420,
}

return Booths