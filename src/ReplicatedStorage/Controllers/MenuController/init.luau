-- Services --
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Data = require(ReplicatedStorage.Source.Data.Gui.Menus)

local Fusion = require(ExPackages.Fusion)
local Signal = require(ExPackages.Signal)
local Knit = require(ExPackages.Knit)

local OnChange = Fusion.OnChange
local peek = Fusion.peek

local ModuleHandler = require(ReplicatedStorage.Source.Classes.ModuleHandler)

-- Controller
local MenuController = Knit.CreateController { Name = "MenuController" }
MenuController.MenuOpened = Signal.new()
MenuController.MenuClosed = Signal.new()

-- Types --
type Self = typeof(MenuController)

-- Local --
local player = Players.LocalPlayer

local scope = Fusion:scoped()

local menus: { [string]: { instance: ScreenGui, scope: Fusion.Scope, shown: Fusion.Value<boolean> } } = {}
local menuIds: { [string]: string } = {}

function MenuController:SetMenu(menuName: string, ...)
	self.currentMenuId:set(menuIds[menuName])
	self:CallMenuFunction(menuName, "shown", ...)
end

function MenuController:OpenMenu(menuName: string, ...)
	local id = menuIds[menuName]
	menus[id].shown:set(true)
	
	self:CallMenuFunction(menuName, "shown", ...)
	self.MenuOpened:Fire(menuName)
end

function MenuController:CloseMenu(menuName: string, ...)
	local id = menuIds[menuName]
	menus[id].shown:set(false)
	if peek(self.currentMenuId) == id then
		self.currentMenuId:set(nil)
	end
	
	self:CallMenuFunction(menuName, "hidden", ...)
	self.MenuClosed:Fire(menuName)
end

function MenuController:CallMenuFunction(menuName: string, functionKey: string, ...)
	for otherMenuName, mod in self.moduleHandler.requiredModules do
		if otherMenuName ~= menuName then
			continue
		end
		local func = mod[functionKey]
		if func then
			func(...)
		end
	end
end

function MenuController:ObserveMenuClosing(menuName: string, callback: () -> ())
	return self.MenuClosed:Connect(function(closedMenuName: string)
		if closedMenuName ~= menuName then
			return
		end
		callback()
	end)
end

function MenuController:ObserveMenuOpening(menuName: string, callback: () -> ())
	return self.MenuOpened:Connect(function(openedMenuName: string)
		if openedMenuName ~= menuName then
			return
		end
		callback()
	end)
end

function MenuController:IsOpen(menuName: string)
	local id = menuIds[menuName]
	if not id then
		return false
	end
	local menuData = menus[id]
	if not menuData then
		return false
	end
	
	return peek(menuData.shown)
end

function MenuController:GetCurrentMenu()
	local currentMenuData = menus[peek(self.currentMenuId)]
	return currentMenuData and currentMenuData.instance or nil
end

function MenuController:ManageNewMenu(taggedMenu: ScreenGui)
	if not taggedMenu:IsDescendantOf(player) then
		return
	end
	
	local tempScope = Fusion:scoped()
	local shown: Fusion.Value<boolean> = tempScope:Value(taggedMenu.Enabled)
	
	tempScope:Hydrate(taggedMenu) {
		Enabled = tempScope:Computed(function(use: Fusion.Use)
			return use(shown)
		end),
	}
	
	local id = HttpService:GenerateGUID()
	taggedMenu:SetAttribute("Id", id)
	menus[id] = {
		instance = taggedMenu,
		
		scope = tempScope,
		shown = shown,
	}
	menuIds[taggedMenu.Name] = id
	
	for _, menuMod in self.moduleHandler.requiredModules do
		if menuMod.MenuName ~= taggedMenu.Name then
			continue
		end
		
		local menuLoaded = menuMod.menuLoaded
		if menuLoaded then
			menuLoaded(taggedMenu)
		end
	end
end

function MenuController:ManageMenuRemoving(taggedMenu: ScreenGui)
	if not taggedMenu:IsDescendantOf(player) then
		return
	end
	
	local id = taggedMenu:GetAttribute("Id")
	local menuData = menus[id]
	if menuData then
		--menuData.scope:doCleanup()
		menus[id] = nil
	end
	
	if menuIds[taggedMenu.Name] then
		menuIds[taggedMenu.Name] = nil
	end
end

function MenuController:KnitInit()
	self.moduleHandler = ModuleHandler.new(script.Menus)
	
	self.currentMenuId = scope:Value(nil) :: Fusion.Value<string?>
	scope:Observer(self.currentMenuId):onChange(function()
		local newId = peek(self.currentMenuId)
		if newId then
			local menuData = menus[newId]
			menuData.shown:set(true)
			
			self.MenuOpened:Fire(menuData.instance)
		end
	end)
	
	CollectionService:GetInstanceAddedSignal(Data.MENU_TAG):Connect(function(taggedMenu)
		self:ManageNewMenu(taggedMenu)
	end)
	CollectionService:GetInstanceRemovedSignal(Data.MENU_TAG):Connect(function(taggedMenu)
		self:ManageMenuRemoving(taggedMenu)
	end)
	for _, taggedMenu in CollectionService:GetTagged(Data.MENU_TAG) do
		self:ManageNewMenu(taggedMenu)
	end
end

return MenuController