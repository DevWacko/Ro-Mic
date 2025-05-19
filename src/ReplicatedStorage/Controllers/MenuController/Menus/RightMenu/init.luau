-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Containers --
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Source = ReplicatedStorage:WaitForChild("Source")
local Data = Source:WaitForChild("Data")

-- Modules --
local MainData = require(Data:FindFirstChild("Gui"):FindFirstChild("RightMenu"))
local Memory = require(Data:FindFirstChild("Player"):FindFirstChild("Memory"))

local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local peek = Fusion.peek

local manageModificationFrame = require(script.manageModificationFrame)
local manageSettingsFrame = require(script.manageSettingsFrame)
local manageFriendsInvite = require(script.manageFriendsInvite)
local manageServersFrame = require(script.manageServersFrame)
local manageProfileFrame = require(script.manageProfileFrame)
local manageToolsFrame = require(script.manageToolsFrame)

-- Main Module --
local RightMenu = { MenuName = "RightMenu" }

-- Local --
local tempScope: Fusion.Scope
local menuIsShown: Fusion.Value<boolean>

local mainFrame: Frame

local mainMenu: Frame
local menuButtons: ScrollingFrame

local controller

local teleportingService
local memoryService

RightMenu.init = function()
	tempScope = Fusion:scoped()
	
	controller = Knit.GetController("MenuController")
	
	teleportingService = Knit.GetService("TeleportingService")
	memoryService = Knit.GetService("MemoryService")
end

local function manageMenuButtons()
	for _, menuButton: GuiButton? in menuButtons:GetChildren() do
		local button = menuButton:FindFirstChildWhichIsA("ImageButton")
		if not button then
			continue
		end
		
		local menu: Frame? = mainFrame:FindFirstChild(menuButton.Name)
		if not menu or not menu:IsA("Frame") then
			continue
		end
		
		table.insert(tempScope, button.MouseButton1Click:Connect(function()
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

local function manageMenuToggle()
	local openCloseButton: GuiButton = mainFrame:FindFirstChild("Open/Close")
	
	menuIsShown = tempScope:Value(openCloseButton:GetAttribute("ShowingTarget") == nil)
	tempScope:Observer(menuIsShown):onChange(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not peek(menuIsShown))
	end)
	tempScope:Hydrate(openCloseButton) {
		Rotation = tempScope:Spring(tempScope:Computed(function(use: Fusion.Use)
			return use(menuIsShown) and 180 or 0
		end), 25, 0.8)
	}
	
	table.insert(tempScope, openCloseButton:GetAttributeChangedSignal("ShowingTarget"):Connect(function()
		menuIsShown:set(openCloseButton:GetAttribute("ShowingTarget"))
	end))
end

RightMenu.menuLoaded = function(menu: ScreenGui)
	tempScope:doCleanup()
	
	mainFrame = menu:WaitForChild("Main")
	
	mainMenu = mainFrame:WaitForChild("Main Menu")
	menuButtons = mainMenu:FindFirstChild("Contents"):FindFirstChild("Menu")
	
	manageModificationFrame(tempScope, mainFrame)
	manageSettingsFrame(tempScope, mainFrame)
	manageFriendsInvite(tempScope, mainMenu)
	manageProfileFrame(tempScope, mainFrame)
	manageToolsFrame(tempScope, mainFrame)
	
	manageMenuButtons()
	manageMenuToggle()
	
	manageServersFrame(tempScope, mainFrame, teleportingService, memoryService)
end

return RightMenu