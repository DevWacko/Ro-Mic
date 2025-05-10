-- Services --
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Containers --
local Packages = ReplicatedStorage.Packages

-- Modules --
local Data = require(ReplicatedStorage.Source.Data.Gui.Menus)

local Fusion = require(Packages.Fusion)
local Signal = require(Packages.Signal)
local Knit = require(Packages.Knit)

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
end

function MenuController:CloseMenu(menuName: string, ...)
	local id = menuIds[menuName]
	menus[id].shown:set(false)
	if peek(self.currentMenuId) == id then
		self.currentMenuId:set(nil)
	end
	
	self:CallMenuFunction(menuName, "closed", ...)
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

function MenuController:SendToClass(menuName: string, dataType: string, ...)
	self.menuClasses[menuName]:RecieveData(dataType, ...)
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

function MenuController:GetMenuModule(menuName: string)
	return self.moduleHandler.requiredModules[menuName]
end

function MenuController:GetCurrentMenu()
	local currentMenuData = menus[peek(self.currentMenuId)]
	return currentMenuData and currentMenuData.instance or nil
end

function MenuController:GetMenu(menuName: string)
	return menus[menuName].instance
end

function MenuController:ManageNewMenu(taggedMenu: ScreenGui)
	if not taggedMenu:IsDescendantOf(player) then
		return
	end
	
	local tempScope = Fusion:scoped()
	local shown: Fusion.Value<boolean> = tempScope:Value(taggedMenu.Enabled)
	
	local mainFrame: Frame? = taggedMenu:FindFirstChild("Main")
	if mainFrame and not taggedMenu:GetAttribute("IgnoreAnimation") then
		local startPos = mainFrame.Position
		local startRot = mainFrame.Rotation
		
		local hiddenPos = startPos + UDim2.fromScale(0, 0.1)
		local hiddenRot = function()
			return startRot - math.random(-15, 15)
		end
		
		local position: Fusion.Value<Udim2> = tempScope:Value(hiddenPos)
		local posSpring: Fusion.Spring = tempScope:Spring(position, 15, 0.7)
		
		local rotation: Fusion.Value<number> = tempScope:Value(hiddenRot())
		local rotSpring: Fusion.Spring = tempScope:Spring(rotation, 15, 0.7)
		
		tempScope:Hydrate(mainFrame) {
			Position = posSpring,
			Rotation = rotSpring,
		}
		
		tempScope:Observer(shown):onBind(function()
			local isShown = peek(shown)
			position:set(isShown and startPos or hiddenPos)
			rotation:set(isShown and startRot or hiddenRot())
		end)
	end
	
	tempScope:Hydrate(taggedMenu) {
		Enabled = tempScope:Computed(function(use: Fusion.Use)
			return use(shown)
		end),
		[OnChange("Enabled")] = function()
			if taggedMenu.Enabled == true then
				self.MenuOpened:Fire(taggedMenu.Name)
			elseif taggedMenu.Enabled == false then
				self.MenuClosed:Fire(taggedMenu.Name)
			end
		end
	}
	
	local id = HttpService:GenerateGUID()
	taggedMenu:SetAttribute("Id", id)
	menus[id] = {
		instance = taggedMenu,
		
		scope = tempScope,
		shown = shown,
	}
	menuIds[taggedMenu.Name] = id
	
	local menuClass: ModuleScript? = script.Classes:FindFirstChild(taggedMenu.Name)
	if menuClass then
		self.menuClasses[menuClass.Name] = require(menuClass).new(taggedMenu)
	end
	
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
	self.menuClasses = {}
	
	self.currentMenuId = scope:Value(nil) :: Fusion.Value<string?>
	scope:Observer(self.currentMenuId):onChange(function()
		local newId = peek(self.currentMenuId)
		if newId then
			local menuData = menus[newId]
			menuData.shown:set(true)
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