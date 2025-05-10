-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage:WaitForChild("Packages")

-- Modules --
local Fusion = require(Packages:FindFirstChild("Fusion"))
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(Packages:FindFirstChild("Knit"))

local peek = Fusion.peek

local RightMenuData = require(ReplicatedStorage:WaitForChild("Source"):FindFirstChild("Data"):FindFirstChild("Gui"):FindFirstChild("RightMenu"))

local handleSettingObject = require(script.Parent.handleSettingObject)

-- Local --
local scope: Fusion.Scope
local trove: Trove.Trove

local profileMainFrame: Frame

local playerDataService
local settingsService
local menuController

local player = Players.LocalPlayer

local function manageBio()
	local bioFrame: Frame = profileMainFrame:FindFirstChild("Bio")
	local textBox: TextBox = bioFrame:FindFirstChild("Bio"):FindFirstChild("TextBox")
	
	playerDataService:GetValue("Settings"):andThen(function(playerSettings)
		local bioText: string?
		if playerSettings then
			bioText = playerSettings.Bio
		end
		
		local characters: Fusion.Value<number> = scope:Value(bioText and string.len(bioText) or 0)
		local maxChars = RightMenuData.Profile.MAX_BIO_CHARACTERS
		
		local function charLimitSurpassed()
			return peek(characters) > maxChars
		end
		
		local saveButton: TextButton = bioFrame:FindFirstChild("SaveBio")
		local saveLabel: GuiLabel = saveButton:FindFirstChild("Label")
		local function setSaveText()
			local count = `({peek(characters)}/{maxChars})`
			saveLabel.Text = charLimitSurpassed() and count or `Save {count}`
		end
		local function setGradients(success)
			saveButton:FindFirstChild("Green").Enabled = success
			saveButton:FindFirstChild("Red").Enabled = not success
		end
		setSaveText()
		
		table.insert(scope, saveButton.MouseButton1Click:Connect(function()
			if charLimitSurpassed() then
				return
			end
			settingsService:SetSettingAttempt("Bio", textBox.Text):andThen(function(success: boolean)
				saveLabel.Text = success and "Saved!" or "Failed to save"
				
				setGradients(success)
				
				task.delay(1, function()
					setGradients(true)
					setSaveText()
				end)
			end)
		end))
		
		scope:Observer(characters):onBind(function()
			setSaveText()
			setGradients(not charLimitSurpassed())
		end)
		
		textBox.Text = bioText or ""
		table.insert(scope, textBox:GetPropertyChangedSignal("Text"):Connect(function()
			characters:set(string.len(textBox.Text))
		end))
	end)
end

local function manageViewingOwnProfile()
	local viewButton: GuiButton = profileMainFrame:FindFirstChild("ProfileView"):FindFirstChild("ViewProfile")
	
	local function checkViewingProfile()
		return peek(menuController:GetMenuModule("PlayerProfile").playerViewing) == player
	end
	
	local isViewingProfile: Fusion.Value<boolean> = scope:Value(checkViewingProfile())
	scope:Hydrate(viewButton:FindFirstChild("Label")) {
		Text = scope:Computed(function(use: Fusion.Use)
			return use(isViewingProfile) and "Close Profile" or "View Profile"
		end),
	}
	
	trove:Add(menuController:ObserveMenuClosing("PlayerProfile", function()
		isViewingProfile:set(false)
	end))
	
	table.insert(scope, viewButton.MouseButton1Click:Connect(function()
		if not peek(isViewingProfile) then
			menuController:OpenMenu("PlayerProfile", player, false)
			isViewingProfile:set(true)
		else
			menuController:CloseMenu("PlayerProfile", true)
			isViewingProfile:set(false)
		end
	end))
end

local function manageSettings()
	for _, settingObject: Instance in profileMainFrame:FindFirstChild("Settings"):GetChildren() do
		local settingType = settingObject:GetAttribute("SettingType")
		if not settingType then
			continue
		end
		handleSettingObject(scope, settingObject, settingsService)
	end
end

local function managePlayerIcon()
	local playerIconId: string? do
		local success, err = pcall(function()
			playerIconId = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150)
		end)
	end
	profileMainFrame:FindFirstChild("ProfileView"):FindFirstChild("Player"):FindFirstChild("Player"):FindFirstChild("Icon").Image = playerIconId or ""
end

local function manageProfileFrame(tempScope: Fusion.Scope, mainFrame: Frame)
	scope = tempScope
	
	trove = Trove.new()
	table.insert(scope, trove)
	
	playerDataService = Knit.GetService("PlayerDataService")
	menuController = Knit.GetController("MenuController")
	settingsService = Knit.GetService("SettingsService")
	
	profileMainFrame = mainFrame:FindFirstChild("Profile"):FindFirstChild("Main")
	
	if player:GetAttribute("ProfileLoaded") then
		task.spawn(manageSettings)
	else
		settingsService.SettingsLoaded:Connect(task.spawn, manageSettings)
	end
	
	task.spawn(manageViewingOwnProfile)
	task.spawn(managePlayerIcon)
	task.spawn(manageBio)	
end

return manageProfileFrame