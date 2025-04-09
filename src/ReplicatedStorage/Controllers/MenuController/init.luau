-- Services --
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local peek = Fusion.peek

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Controller
local MenuController = Knit.CreateController { Name = "MenuController" }

-- Types --
type Self = typeof(MenuController)

-- Constants --
local TAG = "Menu"

-- Local --
local menus: { [ScreenGui]: {
	scope: Fusion.Scope,
	shown: Fusion.Value<boolean>,
} } = {}

function MenuController:SetMenu(taggedMenu: ScreenGui, ...)
	local menuData = menus[taggedMenu]
	if not menuData then
		return
	end
	
	local currentMenu = peek(self.currentMenu)
	local currentMenuData = menus[currentMenu]
	if currentMenuData then
		currentMenuData.shown:set(false)
	end
	
	for _, menuMod in self.moduleHandler.requiredModules do
		if menuMod.MenuName ~= taggedMenu.Name then
			continue
		end
		
		local shown = menuMod.shown
		if shown then
			shown(taggedMenu, ...)
		end
	end
	
	menuData.shown:set(true)
end

function MenuController:CloseMenu(taggedMenu: ScreenGui)
	local menuData = menus[taggedMenu]
	if not menuData then
		return
	end
	menuData.shown:set(false)
	
	if peek(self.currentMenu) == taggedMenu then
		self.currentMenu:set(nil)
	end
end

function taggedMenuAdded(taggedMenu: ScreenGui)
	if not taggedMenu:IsDescendantOf(Players.LocalPlayer) then
		return
	end
	
	local scope = Fusion:scoped()
	local shown: Fusion.Value<boolean> = scope:Value(taggedMenu.Enabled)
	
	scope:Observer(shown):onBind(function()
		taggedMenu.Enabled = peek(shown)
	end)
	
	menus[taggedMenu] = {
		scope = scope,
		shown = shown,
	}
	
	for _, mod in MenuController.moduleHandler.requiredModules do
		if mod.MenuName ~= taggedMenu.Name then
			continue
		end
		local menuLoaded = mod.menuLoaded
		if menuLoaded then
			menuLoaded(taggedMenu)
		end
	end
end

function taggedMenuRemoved(taggedMenu: ScreenGui)
	local menuData = menus[taggedMenu]
	if menuData then
		menuData.scope:doCleanup()
		menus[taggedMenu] = nil
	end
end

function MenuController:KnitInit()
	self.moduleHandler = ModuleHandler.new(script.Menus)
	
	local scope = Fusion:scoped()
	self.currentMenu = scope:Value(nil) :: Fusion.Value<ScreenGui?>
	
	CollectionService:GetInstanceAddedSignal(TAG):Connect(taggedMenuAdded)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(taggedMenuRemoved)
	for _, taggedMenu in CollectionService:GetTagged(TAG) do
		taggedMenuAdded(taggedMenu)
	end
end

return MenuController