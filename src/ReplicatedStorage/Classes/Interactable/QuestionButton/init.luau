local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Selecting = require(script.Selecting)
local Questions = require(script.Questions)

local QuestionButton = {}
QuestionButton.__index = QuestionButton

export type self = typeof(QuestionButton)

function QuestionButton.new(model: Model, id: number)
	local self = setmetatable({}, QuestionButton)
	
	self.IsServer, self.IsClient = RunService:IsServer(), RunService:IsClient()
	self.Data = Knit.Data.Interacting.QuestionGame
	
	self.Billboards = ReplicatedStorage.Assets.Gui.Billboards.QuestionButton
	self.Model = model
	
	self.Trove = Trove.new()
	
	self.Id = id
	
	if self.IsServer then
		self.Model:SetAttribute("Id", self.Id)
		
		self.QuestionsType = self.Data.START_QUESTION_TYPE
		self.Question = ""
	elseif self.IsClient then
		self.Scope = Fusion:scoped()
		self.QuestionsType = self.Scope:Value("")
		
		self.MenuController = Knit.GetController("MenuController")
		
		self.LocalPlayer = Players.LocalPlayer
	end
	
	Selecting(self)
	--Questions(self)
	
	return self
end

function QuestionButton:Destroy()
	if self.IsServer then
		self.Trove:Destroy()
	end
end

return QuestionButton
