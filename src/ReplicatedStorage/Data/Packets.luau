local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Source.Utils.Packet)

local Packets = {}

-- Question Buttons
Packets.QuestionButton = {
	-- Selecting Question Type
	SetSelecting = Packet("SetSelecting", Packet.String, Packet.Boolean8),
	SelectQuestionsType = Packet("SelectQuestionsType", Packet.String, Packet.String),
	GetQuestionsType = Packet("GetQuestionsType", Packet.String, Packet.String):Response(Packet.String),
	
	-- Changing Question
	ChangeQuestion = Packet("ChangeQuestion", Packet.String),
	AddQuestion = Packet("SetQuestion", Packet.String, Packet.String)
}

return Packets