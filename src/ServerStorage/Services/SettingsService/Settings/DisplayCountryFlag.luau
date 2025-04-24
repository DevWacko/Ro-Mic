-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage:FindFirstChild("Packages")

-- Modules --
local Fusion = require(Packages:FindFirstChild("Fusion"))
local Knit = require(Packages:FindFirstChild("Knit"))

local Children = Fusion.Children
local peek = Fusion.peek

local getFlagEmoji = require(ReplicatedStorage:FindFirstChild("Source"):FindFirstChild("Utils"):FindFirstChild("Player"):FindFirstChild("getFlagEmoji"))

-- Main Module --
local DisplayCountryFlag = {
	PlayerDebounces = {} :: { [Player]: boolean },
	DefaultValue = false,
}

-- Local --
local tempScopes: { [Player]: Fusion.Scope } = {}
local displayScopes: { [Player]: Fusion.Scope } = {}
local playersEnabled: { [Player]: Fusion.Value<boolean> } = {}

local playerService
local service

DisplayCountryFlag.init = function()
	playerService = Knit.GetService("PlayerService")
	service = Knit.GetService("SettingsService")
end

DisplayCountryFlag.setSettingAttempt = function(player: Player, toggled: any, ...)
	local data = { ... }
	
	assert(toggled ~= nil and typeof(toggled) == "boolean", " value was nil or not a boolean")
	
	return true, toggled
end

DisplayCountryFlag.playerAdded = function(player: Player)
	local tempScope = Fusion:scoped()
	tempScopes[player] = tempScope
	
	local display = tempScope:Value(service:CheckSetting(player, "DisplayCountryFlag") or DisplayCountryFlag.DefaultValue)
	playersEnabled[player] = display
	
	local displayScope = Fusion:scoped()
	table.insert(tempScope, displayScope)
	displayScopes[player] = displayScope
	
	local function setDisplaying(char: Model)
		if not char then
			return
		end
		
		if peek(display) then
			local head = char:FindFirstChild("Head")
			if not head then
				return
			end
			local attach = head:FindFirstChild("HatAttachment")
			if not attach then
				return
			end
			
			local size = displayScope:Value(UDim2.new())
			displayScope:New "BillboardGui" {
				Name = "CountryFlagDisplay",
				Parent = attach,
				
				Size = UDim2.fromScale(1, 1),
				AlwaysOnTop = true,
				
				StudsOffset = Vector3.yAxis * 2,
				MaxDistance = 50,
				
				[Children] = {
					displayScope:New "TextLabel" {
						Name = "Flag",
						
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.fromScale(0.5, 1),
						Size = displayScope:Spring(size, 25, 0.4),
						
						BackgroundTransparency = 1,
						
						Text = getFlagEmoji(playerService:GetPlayerCountry(player)),
						TextScaled = true,
					},
				},
			}
			size:set(UDim2.fromScale(1, 1))
		else
			displayScope:doCleanup()
		end
	end
	
	table.insert(tempScope, player.CharacterAdded:Connect(function(char)
		task.delay(1, setDisplaying, char)
	end))
	if player.Character then
		setDisplaying(player.Character)
	end
	tempScope:Observer(display):onBind(function()
		setDisplaying(player.Character)
	end)
end

DisplayCountryFlag.playerRemoving = function(player: Player)
	local tempScope = tempScopes[player]
	if tempScope then
		tempScope:doCleanup()
		tempScopes[player] = nil
	end
	local displayScope = displayScopes[player]
	if displayScope then
		displayScopes[player] = nil
	end
	local val = playersEnabled[player]
	if val then
		playersEnabled[player] = nil
	end
end

DisplayCountryFlag.updated = function(player: Player, toggled: any)
	DisplayCountryFlag.PlayerDebounces[player] = true
	task.delay(1, function()
		DisplayCountryFlag.PlayerDebounces[player] = false
	end)
	
	local displayValue = playersEnabled[player]
	if displayValue then
		displayValue:set(toggled)
	end
end

return DisplayCountryFlag