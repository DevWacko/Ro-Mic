-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage:WaitForChild("ExPackages")

-- Packages --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local peek = Fusion.peek

-- Main Module --
local RightMenu = { MenuName = "RightMenu" }

-- Local --
local tempScope = Fusion:scoped()
local serversScope = Fusion:scoped()

local mainFrame: Frame

local mainMenu: Frame
local menuButtons: ScrollingFrame
local serverFrame: Frame

local controller
local memoryService

RightMenu.init = function()
	controller = Knit.GetController("MenuController")
	memoryService = Knit.GetService("MemoryService")
end

RightMenu.shown = function(menu: ScreenGui, ...)
	
end

local function manageMenuButtons()
	for _, menuButton: GuiButton? in menuButtons:GetChildren() do
		if not menuButton:IsA("GuiButton") then
			continue
		end
		
		local menu: Frame? = mainFrame:FindFirstChild(menuButton.Name)
		if not menu or not menu:IsA("Frame") then
			continue
		end
		
		table.insert(tempScope, menuButton.MouseButton1Click:Connect(function()
			mainMenu.Visible = false
			menu.Visible = true
		end))
		
		local navigateFrame: Frame? = menu:FindFirstChild("Navigate")
		if not navigateFrame then
			return
		end
		local backButton: GuiButton? = navigateFrame:FindFirstChild("Back")
		if not backButton or not backButton:IsA("GuiButton") then
			return
		end
		table.insert(tempScope, backButton.MouseButton1Click:Connect(function()
			menu.Visible = false
			mainMenu.Visible = true
		end))
	end
end

local function refreshServers()
	serversScope:doCleanup()
	memoryService:GetServersInfoAttempt():andThen(function(serversInfo: MemoryStoreSortedMap?)
		print(serversInfo)
	end)
end

local function manageServerFrame()
	-- task.spawn(function()
	-- 	while task.wait(5) do
	-- 		refreshServers()
	-- 	end
	-- end)
end

RightMenu.menuLoaded = function(menu: ScreenGui)
	tempScope:doCleanup()
	
	mainFrame = menu:WaitForChild("Main")
	
	mainMenu = mainFrame:WaitForChild("Main Menu")
	serverFrame = mainFrame:WaitForChild("Servers")
	menuButtons = mainMenu:FindFirstChild("Contents"):FindFirstChild("Menu")
	
	local openCloseButton: GuiButton = mainFrame:FindFirstChild("Open/Close")
	table.insert(tempScope, openCloseButton:GetAttributeChangedSignal("ShowingTarget"):Connect(function()
		if peek(openCloseButton:GetAttribute("ShowingTarget")) then
			controller:CloseMenu("LeaderboardServiceUI")
		else
			controller:OpenMenu("LeaderboardServiceUI")
		end
	end))
	
	manageServerFrame()
	manageMenuButtons()
end

return RightMenu