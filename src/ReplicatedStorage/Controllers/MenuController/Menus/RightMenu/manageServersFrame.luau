-- Services --
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage:WaitForChild("Packages")

-- Packages --
local Fusion = require(Packages:FindFirstChild("Fusion"))
local Knit = require(Packages:FindFirstChild("Knit"))

local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local peek = Fusion.peek

local RightMenuData = require(ReplicatedStorage:WaitForChild("Source"):FindFirstChild("Data"):FindFirstChild("Gui"):FindFirstChild("RightMenu"))

-- Types --
export type ServerInfo = {
	Type: string,
	Location: string,
	BuildVersion: string,
	Players: { [number]: number },
}

-- Local --
local scope: Fusion.Scope

local serversData: Fusion.Value<{ [string]: ServerInfo }>
local isLoadingServers: Fusion.Value<boolean>

local serversFrame: Frame

local teleportingService
local memoryService

local function refreshServers()
	if peek(isLoadingServers) then
		return
	end
	isLoadingServers:set(true)
	serversData:set({})
	
	memoryService:GetServersAttempt():andThen(function(recievedServersData)
		task.delay(2, function()
			isLoadingServers:set(false)
			if not recievedServersData then
				return
			end
			
			local newServersData = {}
			for serverType, servers in recievedServersData do
				for serverId, serverData in servers do
					serverData.Type = serverType
					newServersData[serverId] = serverData
				end
			end
			serversData:set(newServersData)
		end)
	end)
end

local function manageServersFrame(tempScope: Fusion.Scope, mainFrame: Frame, sentTeleportService, sentMemoryService)
	scope = tempScope
	serversData = scope:Value({})
	isLoadingServers = scope:Value(false)
	
	serversFrame = mainFrame:FindFirstChild("Servers")
	
	teleportingService = sentTeleportService
	memoryService = sentMemoryService
	
	table.insert(scope, serversFrame:FindFirstChild("17+Servers"):FindFirstChild("Teleport").MouseButton1Click:Connect(function()
		teleportingService:TeleportTo17Plus()
	end))
	
	local listOfServersFrame: Frame = serversFrame:FindFirstChild("ListOfServers")
	local serverContents = listOfServersFrame:FindFirstChild("Contents")
	local serversNavigateFrame: Frame = serversFrame:FindFirstChild("Navigate")
	
	local serversTypeIndex: Fusion.Value<number> = scope:Value(1)
	scope:Observer(serversTypeIndex):onBind(function()
		listOfServersFrame.Visible = peek(serversTypeIndex) == 1
		serversFrame:FindFirstChild("17+Servers").Visible = peek(serversTypeIndex) == 2
	end)
	for _, serversTypeButton: GuiButton? in serversNavigateFrame:FindFirstChild("Upper"):GetChildren() do
		if not serversTypeButton:IsA("GuiButton") then
			continue
		end
		local index = serversTypeButton:GetAttribute("ServerTypeIndex")
		if not index then
			continue
		end
		table.insert(scope, serversTypeButton.MouseButton1Click:Connect(function()
			serversTypeIndex:set(index)
		end))
	end
	
	local function getTemplatesWithData()
		local templates: { [Frame]: ServerInfo } = {}
		for _, serverTemplate: Frame? in serverContents:GetChildren() do
			if not serverTemplate:IsA("Frame") then
				continue
			end
			local serverData = peek(serversData)[serverTemplate.Name]
			if not serverData then
				continue
			end
			templates[serverTemplate] = serverData
		end
		return templates
	end
	
	local serverFilterDropdownButton = serversNavigateFrame:FindFirstChild("Lower"):FindFirstChild("ServerFilter")
	
	local filterButtons do
		filterButtons = {}
		for _, filterButton: TextButton? in serverFilterDropdownButton:FindFirstChild("Filter Dropdown"):GetChildren() do
			if not filterButton:IsA("TextButton") then
				continue
			end
			table.insert(filterButtons, filterButton)
		end
	end
	
	local filterButtonSelected: Fusion.Value<TextButton> do
		local default: TextButton?
		for _, filterButton in filterButtons do
			if filterButton:GetAttribute("Default") == true then
				default = filterButton
			end
		end
		filterButtonSelected = scope:Value(default)
	end
	scope:Observer(filterButtonSelected):onBind(function()
		local filterButton: TextButton? = peek(filterButtonSelected)
		if filterButton then
			serverFilterDropdownButton:FindFirstChild("Selected"):FindFirstChild("Filter").Text = filterButton:GetAttribute("Text") or "-"
		end
		
		if filterButton.Name == "Ascending" then
			for temp, info in getTemplatesWithData() do
				temp.LayoutOrder = 1 - #info.Players
			end
		elseif filterButton.Name == "Descending" then
			for temp, info in getTemplatesWithData() do
				temp.LayoutOrder = #info.Players
			end
		elseif filterButton.Name == "Relevant" then
			for temp, _ in getTemplatesWithData() do
				temp.LayoutOrder = math.random(1, 100)
			end
		end
	end)
	
	for _, filterButton: TextButton in filterButtons do
		scope:Hydrate(filterButton) {
			BackgroundColor3 = scope:Computed(function(use: Fusion.Use)
				return use(filterButtonSelected) == filterButton and Color3.fromRGB(61, 61, 61) or Color3.fromRGB(232, 232, 232)
			end),
			TextColor3 = scope:Computed(function(use: Fusion.Use)
				return use(filterButtonSelected) == filterButton and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
			end),
			[OnEvent("MouseButton1Click")] = function()
				filterButtonSelected:set(filterButton)
			end,
		}
	end
	
	local loadingTextTrans: Fusion.Value<number> = scope:Value(1)
	local loadingText: Fusion.Value<string> = scope:Value("Loading Servers...")
	local loadingShown: Fusion.Value<boolean> = scope:Value(true)
	
	local loadingTextTransSpring: Fusion.Spring = scope:Spring(loadingTextTrans, 10, 0.9)
	scope:Hydrate(serverContents:FindFirstChild("Loading")) {
		Visible = loadingShown,
		
		TextTransparency = loadingTextTransSpring,
		Text = loadingText,
	}
	local loop = false
	scope:Observer(isLoadingServers):onBind(function()
		loop = peek(isLoadingServers)
		if not loop then
			return
		end
		task.spawn(function()
			while loop do
				loadingTextTransSpring:setVelocity(-1)
				task.wait(1)
			end
		end)
	end)
	scope:Computed(function(use: Fusion.Use)
		local count = 0
		for _, _ in use(serversData) do
			count += 1
		end
		local noServers = count == 0 and not use(isLoadingServers)
		
		loadingTextTrans:set(noServers and 0.7 or 1)
		loadingText:set(noServers and "No Servers Found" or "Receiving Servers...")
		
		loadingShown:set(count == 0)
	end)
	
	table.insert(scope, serversNavigateFrame:FindFirstChild("Lower"):FindFirstChild("RefreshServers").MouseButton1Click:Connect(refreshServers))
	
	scope:Hydrate(serverContents) {
		[Children] = {
			scope:ForPairs(serversData, function(use: Fusion.Use, scope: Fusion.Scope, serverId: string, serverInfo: ServerInfo)
				local serverTemplate: Frame = RightMenuData.Servers.SERVER_TEMPLATE:Clone()
				serverTemplate.Name = serverId
				
				serverTemplate:FindFirstChild("ServerID").Text = `Server {string.sub(string.upper(serverId), 0, 4)}`
				serverTemplate:FindFirstChild("PlayerCount").Text = `{#serverInfo.Players}/{Players.MaxPlayers}`
				
				local playerPreviewFrame: Frame = serverTemplate:FindFirstChild("PlayerPreview")
				
				local additionalPlayers = 0
				for i, userId in serverInfo.Players do
					if i > RightMenuData.Servers.MAX_PFP_PREVIEWS then
						additionalPlayers += 1
						continue
					end
					local pfpPreviewTemplate = RightMenuData.Servers.PFP_PREVIEW_TEMPLATE:Clone()
					pfpPreviewTemplate.Parent = playerPreviewFrame
					
					task.spawn(function()
						local pfpImage: string?
						local success, err = pcall(function()
							pfpImage = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
						end)
						if not success then
							warn("There was an error getting thumbnail", err)
						else
							pfpPreviewTemplate.Image =  pfpImage
						end
					end)
				end
				local additionalPlayersLabel: TextLabel = playerPreviewFrame:FindFirstChild("AdditionalPlayers")
				additionalPlayersLabel.Text = `{additionalPlayers}+`
				additionalPlayersLabel.Visible = additionalPlayers > 0
				
				local infoFrame = serverTemplate:FindFirstChild("Info")
				infoFrame:FindFirstChild("ServerLocation").Text = `Server Location: {serverInfo.Location}`
				infoFrame:FindFirstChild("ServerVersion").Text = `Server Version: {serverInfo.BuildVersion}`
				
				local joinButton: GuiButton = serverTemplate:FindFirstChild("Join")
				table.insert(scope, joinButton.MouseButton1Click:Connect(function()
					teleportingService:SafeTeleportToServer(serverId)
				end))
				
				local isCurrentServer = serverId == game.JobId
				joinButton.Visible = not isCurrentServer
				serverTemplate:FindFirstChild("Current").Visible = isCurrentServer
				
				return serverId, serverTemplate
			end)
		}
	}
	refreshServers()
end

return manageServersFrame