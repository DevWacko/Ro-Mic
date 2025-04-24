-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Packages = ReplicatedStorage:FindFirstChild("Packages")

-- Modules --
local Fusion = require(Packages:FindFirstChild("Fusion"))

local OnEvent = Fusion.OnEvent

local function handleSettingObject(scope: Fusion.Scope, settingObject: Instance, settingsService)
	local settingName = settingObject.Name
	
	local settingType = settingObject:GetAttribute("SettingType")
	if settingType == "Toggle" then
		local toggleButton: GuiButton = settingObject:FindFirstChild("Toggle")
		settingsService:CheckSetting(settingName):andThen(function(startToggled: boolean?)
			local toggled: Fusion.Value<boolean> = scope:Value(startToggled)
			scope:Hydrate(toggleButton) {
				BackgroundColor3 = scope:Tween(scope:Computed(function(use: Fusion.Use)
					return use(toggled) and Color3.fromRGB(72, 127, 245) or Color3.fromRGB(221, 221, 221)
				end), TweenInfo.new(0.25)),
				[OnEvent("MouseButton1Click")] = function()
					settingsService:CheckSetting(settingName):andThen(function(currentToggled: boolean?)
						if currentToggled == nil then
							return
						end
						settingsService:SetSettingAttempt(settingName, not currentToggled):andThen(function(success: boolean, newToggled: boolean?)
							if not success then
								return
							end
							toggled:set(newToggled)
						end)
					end)
				end,
			}
			scope:Hydrate(toggleButton:FindFirstChildWhichIsA("Frame")) {
				AnchorPoint = scope:Spring(scope:Computed(function(use: Fusion.Use)
					return use(toggled) and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
				end), 25, 0.7),
				Position = scope:Spring(scope:Computed(function(use: Fusion.Use)
					return use(toggled) and UDim2.fromScale(1, 0.5) or UDim2.fromScale(0, 0.5)
				end), 25, 0.7),
			}
		end)
	elseif settingType == "Slider" then
		settingsService:CheckSetting(settingName):andThen(function(startValue: number?)
			local slider: GuiObject = settingObject:FindFirstChild("Slider")
			slider:SetAttribute("Value", startValue)
			
			table.insert(scope, slider:GetAttributeChangedSignal("Value"):Connect(function()
				settingsService:SetSettingAttempt(settingName, slider:GetAttribute("Value"))
			end))
		end)
	end
end

return handleSettingObject