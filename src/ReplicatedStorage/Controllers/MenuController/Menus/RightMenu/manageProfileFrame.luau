-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage:WaitForChild("Packages")

-- Modules --
local Fusion = require(Packages:FindFirstChild("Fusion"))
local Knit = require(Packages:FindFirstChild("Knit"))

local peek = Fusion.peek

local RightMenuData = require(ReplicatedStorage:WaitForChild("Source"):FindFirstChild("Data"):FindFirstChild("Gui"):FindFirstChild("RightMenu"))

local handleSettingObject = require(script.Parent.handleSettingObject)

-- Local --
local scope: Fusion.Scope

local profileMainFrame: Frame

local playerDataService
local settingsService
local menuController

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
		return peek(menuController:GetMenuModule("PlayerProfile").playerViewing) == Players.LocalPlayer
	end
	
	local isViewingProfile: Fusion.Value<boolean> = scope:Value(checkViewingProfile())
	scope:Hydrate(viewButton:FindFirstChild("Label")) {
		Text = scope:Computed(function(use: Fusion.Use)
			return use(isViewingProfile) and "Close Profile" or "View Profile"
		end),
	}
	
	table.insert(scope, viewButton.MouseButton1Click:Connect(function()
		if not peek(isViewingProfile) then
			menuController:SetMenu("PlayerProfile", Players.LocalPlayer, false)
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

local function manageProfileFrame(tempScope: Fusion.Scope, mainFrame: Frame)
	scope = tempScope
	
	playerDataService = Knit.GetService("PlayerDataService")
	menuController = Knit.GetController("MenuController")
	settingsService = Knit.GetService("SettingsService")
	
	profileMainFrame = mainFrame:FindFirstChild("Profile"):FindFirstChild("Main")
	
	manageViewingOwnProfile()
	manageSettings()
	manageBio()
end

return manageProfileFrame