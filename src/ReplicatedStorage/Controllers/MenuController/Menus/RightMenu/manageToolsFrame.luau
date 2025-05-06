-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Tools = Assets:FindFirstChild("Tools")

-- Modules --
local TableUtil = require(Packages:FindFirstChild("TableUtil"))
local Fusion = require(Packages:FindFirstChild("Fusion"))
local Knit = require(Packages:FindFirstChild("Knit"))

local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local peek = Fusion.peek

local FitViewport = require(ReplicatedStorage.Source.Utils.Calculations.FitViewport)

-- Local --
local scope: Fusion.Scope
local toolsFrame: Frame

local equippedTools: Fusion.Value<{ [number]: Tool }>
local listedTools: Fusion.Value<{ [number]: Tool }>

local savedEquippedTools: { [number]: string } = {}

local toolTemp = Assets:FindFirstChild("Gui"):FindFirstChild("Templates"):FindFirstChild("Tool")

local guiAnimationController
local characterService

local player = Players.LocalPlayer

-- Main Module --
local function manageCategories()
	local categoriesContainer = toolsFrame:FindFirstChild("Navigate"):FindFirstChild("Categories")
	
	local selectedCategoryButton: Fusion.Value<GuiButton> = scope:Value(categoriesContainer:FindFirstChild("AllTools")) -- DEFAULT CATEGORY
	scope:Observer(selectedCategoryButton):onBind(function()
		local categoryButton: GuiButton = peek(selectedCategoryButton)
		
		local newListedTools = {}
		if categoryButton.Name == "AllTools" then
			for _, category: Folder in Tools:GetChildren() do
				for _, tool in category:GetChildren() do
					table.insert(newListedTools, tool)
				end
			end
		else
			for _, tool in Tools:FindFirstChild(categoryButton.Name):GetChildren() do
				table.insert(newListedTools, tool)
			end
		end
		listedTools:set(newListedTools)
	end)
	
	for _, categoryButton: GuiButton? in categoriesContainer:GetChildren() do
		if not categoryButton:IsA("GuiButton") then
			continue
		end
		scope:Hydrate(categoryButton) {
			BackgroundColor3 = scope:Tween(scope:Computed(function(use: Fusion.Use)
				return use(selectedCategoryButton) == categoryButton and Color3.fromRGB(85, 154, 244) or Color3.fromRGB(244, 244, 244)
			end), TweenInfo.new(0.25)),
			TextColor3 = scope:Tween(scope:Computed(function(use: Fusion.Use)
				return use(selectedCategoryButton) == categoryButton and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
			end), TweenInfo.new(0.25)),
			[OnEvent("MouseButton1Click")] = function()
				selectedCategoryButton:set(categoryButton)
			end,
		}
	end
end

local function getToolCategory(toolName: string)
	for _, category: Folder in Tools:GetChildren() do
		for _, tool in category:GetChildren() do
			if tool.Name == toolName then
				return category.Name
			end
		end
	end
end

local function manageItems()
	scope:Hydrate(toolsFrame:FindFirstChild("ToolList")) {
		[Children] = {
			scope:ForValues(listedTools, function(use: Fusion.Use, tempScope: Fusion.Scope, tool: Tool)
				local toolName = tool.Name
				local newTemplate: TextButton = tempScope:Hydrate(toolTemp:Clone()) {
					Name = toolName,
					[OnEvent("MouseButton1Click")] = function()
						if table.find(savedEquippedTools, toolName) then
							return
						end
						characterService:SendAddonEventAttempt("Tools", "EquipTool", toolName, getToolCategory(toolName)):andThen(function(success)
							if not success then
								return
							end
							
							table.insert(savedEquippedTools, toolName)
							equippedTools:set(savedEquippedTools)
						end)
					end,
				}
				tempScope:Hydrate(newTemplate:FindFirstChild("PrimaryBG")) {
					ImageColor3 = scope:Tween(scope:Computed(function(use: Fusion.Use)
						return table.find(use(equippedTools), toolName) and Color3.fromRGB(78, 211, 74) or Color3.fromRGB(85, 154, 244)
					end), TweenInfo.new(0.25)),
				}
				
				local viewport: ViewportFrame = newTemplate:FindFirstChild("ToolViewport")
				local toolClone = tool:Clone()
				local toolModel = Instance.new("Model")
				for _, obj in toolClone:GetChildren() do
					obj.Parent = toolModel
				end
				toolModel.PrimaryPart = toolModel:WaitForChild("Handle")
				toolClone:Destroy()
				FitViewport(toolModel, viewport)
				
				local removeCanvas: CanvasGroup = newTemplate:FindFirstChild("Remove")
				local removeCanvasStartSize = removeCanvas.Size
				tempScope:Hydrate(removeCanvas) {
					Size = scope:Spring(scope:Computed(function(use: Fusion.Use)
						return table.find(use(equippedTools), toolName) and removeCanvasStartSize or UDim2.new()
					end), 25, 0.8),
					GroupTransparency = scope:Tween(scope:Computed(function(use: Fusion.Use)
						return table.find(use(equippedTools), toolName) and 0 or 1
					end), TweenInfo.new(0.25)),
				}
				table.insert(scope, removeCanvas:FindFirstChild("Remove").MouseButton1Click:Connect(function()
					if not table.find(savedEquippedTools, toolName) then
						return
					end
					characterService:SendAddonEventAttempt("Tools", "UnequipTool", toolName):andThen(function(success)
						if not success then
							return
						end
						
						local index = table.find(savedEquippedTools, toolName)
						if index then
							table.remove(savedEquippedTools, index)
							equippedTools:set(savedEquippedTools)
						end
					end)
				end))
				
				newTemplate:FindFirstChild("ToolName").Text = toolName
				
				return newTemplate
			end)
		},
	}
end

local function getPlayerTools()
	local tools = {}
	for _, tool: Tool? in player.Backpack:GetChildren() do
		if not tool:IsA("Tool") then
			continue
		end
		table.insert(tools, tool)
	end
	if player.Character then
		for _, tool: Tool? in player.Character:GetChildren() do
			if not tool:IsA("Tool") then
				continue
			end
			table.insert(tools, tool)
		end
	end
	return tools
end

local function manageClearInventory(mainFrame: Frame)
	local clearInventoryButton: GuiButton = mainFrame:FindFirstChild("ExternalButtons"):FindFirstChild("ClearInventory")
	local openCloseButton: GuiButton = mainFrame:FindFirstChild("Open/Close")
	local function check()
		local locked = #getPlayerTools() == 0 or not openCloseButton:GetAttribute("ShowingTarget")
		if locked then
			clearInventoryButton:AddTag("Locked")
		else
			clearInventoryButton:RemoveTag("Locked")
		end
		guiAnimationController.activeAnimatedClasses[clearInventoryButton].size:set(locked and UDim2.new() or UDim2.fromScale(0.609, 0.7))
	end
	scope:Computed(check)
	openCloseButton:GetAttributeChangedSignal("ShowingTarget"):Connect(check)
	
	table.insert(scope, clearInventoryButton.MouseButton1Click:Connect(function()
		local toolNames = {}
		for _, tool in getPlayerTools() do
			table.insert(toolNames, tool.Name)
		end
		characterService:SendAddonEventAttempt("Tools", "BulkUnequipTools", toolNames):andThen(function(success)
			if not success then
				return
			end
			
			for i = #savedEquippedTools, 1, -1 do
				local toolName = savedEquippedTools[i]
				if table.find(toolNames, toolName) then
					table.remove(savedEquippedTools, i)
				end
			end
			equippedTools:set(savedEquippedTools)
			
			check()
		end)
	end))
end

local function manageToolsFrame(tempScope: Fusion.Scope, mainFrame: Frame)
	toolsFrame = mainFrame:FindFirstChild("Tools")
	
	scope = tempScope
	listedTools = scope:Value({})
	equippedTools = scope:Value({})
	
	guiAnimationController = Knit.GetController("GuiAnimationController")
	characterService = Knit.GetService("CharacterService")
	
	manageClearInventory(mainFrame)
	manageCategories()
	manageItems()
end

return manageToolsFrame