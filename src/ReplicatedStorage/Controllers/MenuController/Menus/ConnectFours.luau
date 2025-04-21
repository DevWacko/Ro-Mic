-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local Fusion = require(ReplicatedStorage.ExPackages.Fusion)

local peek = Fusion.peek

-- Main Module --
local ConnectFours = { MenuName = "" }

-- Local --
local scope = Fusion:scoped()

local playerOne: Fusion.Value<Player?> = scope:Value(nil)
local playerTwo: Fusion.Value<Player?> = scope:Value(nil)

local mainFrame: Frame
local sideFrame: Frame
local playersFrame: Frame

ConnectFours.joinedGame = function(playerName: string)
	if not peek(playerOne) then
		playerOne:set(Players:FindFirstChild(playerName))
	elseif not peek(playerTwo) then
		playerTwo:set(Players:FindFirstChild(playerName))
	end
end

ConnectFours.shown = function(menu: ScreenGui, ...)
	
end

local function managePlayers()
	
end

ConnectFours.menuLoaded = function(menu: ScreenGui)
	mainFrame = menu:FindFirstChild("Main")
	sideFrame = mainFrame:FindFirstChild("SideFrame")
	playersFrame = sideFrame:FindFirstChild("Players")
end

return ConnectFours