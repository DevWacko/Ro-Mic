local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Source.Utils.Packet)

local Packets = {}

-- Question Buttons
Packets.QuestionButton = {
	SetSelecting = Packet("SetSelecting", Packet.String, Packet.Boolean8),
	GetQuestionsType = Packet("GetQuestionsType", Packet.String, Packet.String),
	SelectQuestionsType = Packet("SelectQuestionsType", Packet.String, Packet.String)
}

return Packets