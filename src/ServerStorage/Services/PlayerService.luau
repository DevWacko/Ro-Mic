-- Services --
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Knit = require(Packages.Knit)

-- Service --
local PlayerService = Knit.CreateService { Name = "PlayerService" }

-- Types --
type Self = typeof(PlayerService)

function PlayerService:GetPlayerCountry(player: Player)
	local success, code = pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, player)
	if success and code then
		return self.countries[code]
	end
end

function PlayerService:SetupCountries()
	self.countries = {}

	local success, result = pcall(function()
		return HttpService:GetAsync("http://country.io/names.json")
	end)
	if success and result then
		self.countries = HttpService:JSONDecode(result)
	end
end

function PlayerService:KnitInit()
	self:SetupCountries()
end

return PlayerService