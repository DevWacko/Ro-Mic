-- Services --
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Tooltip = require(ReplicatedStorage.Source.Data.Gui.Tooltip)

local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local Children, OnEvent, OnChange = Fusion.Children, Fusion.OnEvent, Fusion.OnChange
local peek = Fusion.peek

-- Main Module --
local MessageBoards = {
	Tag = "MessageBoard",
}

-- Types --
type Message = {
	position: Udim2,
	size: UDim2,
	
	text: string,
}

-- Local --
local player = Players.LocalPlayer

local mouse = player:GetMouse()

local controller
local service

local scope: Fusion.Scope = Fusion:scoped()
local boardMessages: Fusion.Value<{ [Instance]: Fusion.Value<{ [Player]: Message }> }> = scope:Value({})
local boardSurfaceGuis: { [Instance]: ScreenGui } = {}

local pointObstructed: Fusion.Value<boolean> = scope:Value(false)
local writingSurfaceGui: Fusion.Value<SurfaceGui?> = scope:Value(false)

local surfaceMousePositions: { [SurfaceGui]: Fusion.Value<Vector2> } = {}

local tempScopes: { [Instance]: Fusion.Scope } = {}

function collidesWith(gui1, gui2)
    local gui1_topLeft = gui1.AbsolutePosition
	local gui1_bottomRight = gui1_topLeft + gui1.AbsoluteSize
	local gui2_topLeft = gui2.AbsolutePosition
    local gui2_bottomRight = gui2_topLeft + gui2.AbsoluteSize
	return ((gui1_topLeft.x < gui2_bottomRight.x and gui1_bottomRight.x > gui2_topLeft.x) and (gui1_topLeft.y < gui2_bottomRight.y and gui1_bottomRight.y > gui2_topLeft.y))
end

MessageBoards.init = function()
	controller = Knit.GetController("InteractingController")
	service = Knit.GetService("InteractingService")
	
	local surfaceGuiContainer: Folder = scope:New "Folder" {
		Name = "MessageBoardsurfaceGuis",
		Parent = player:WaitForChild("PlayerGui"),
		[Children] = {
			scope:ForPairs(boardMessages, function(
				_use: Fusion.Use,
				surfaceScope: Fusion.Scope,
				taggedObject: Instance,
				messages: Fusion.Value<{ [Player]: Message }>
			)
				boardSurfaceGuis[taggedObject] = surfaceScope:New "SurfaceGui" {
					Name = taggedObject.Name,
					Adornee = taggedObject,
					
					Brightness = 1,
					
					[Children] = {
						surfaceScope:ForPairs(messages, function(use: Fusion.Use, messageScope: Fusion.Scope, player: Player, messageData: Message)
							return player, messageScope:New "TextBox" {
								Position = messageData.position,
								Size = messageData.size,
								
								TextWrapped = true,
								RichText = true,
								Text = messageData.text,
								
								BackgroundColor3 = Color3.new(0.9, 0.9, 0.9),
								
								[Children] = {
									messageScope:New "UICorner" { CornerRadius = UDim.new(0.1) },
								},
							}
						end),
						surfaceScope:New "Frame" {
							Name = "Backdrop",
							Size = UDim2.fromScale(1, 1),
						},
					},
				}
				return taggedObject, boardSurfaceGuis[taggedObject]
			end)
		},
	}
	
	local writingScope: Fusion.Scope = Fusion:scoped()
	table.insert(scope, writingScope)
	
	scope:Observer(writingSurfaceGui):onChange(function()
		local surfaceGui = peek(writingSurfaceGui)
		
		if surfaceGui then
			local clippingOtherMessage: Fusion.Value<boolean> = writingScope:Value(false)
			
			local textBox: TextBox
			local function checkClipping()
				for _, frame in surfaceGui:GetChildren() do
					if not frame:IsA("TextBox") or frame == textBox then
						continue
					end
					if collidesWith(textBox, frame) then
						clippingOtherMessage:set(true)
						return
					end
				end
				clippingOtherMessage:set(false)
			end
			
			local text = ""
			
			local textBounds: Fusion.Value<Udim2> = writingScope:Value(UDim2.fromOffset(0, 0))
			textBox = writingScope:New "TextBox" {
				Parent = surfaceGui,
				
				Position = writingScope:Computed(function()
					local pos = peek(surfaceMousePositions[surfaceGui])
					return UDim2.fromOffset(pos.X, pos.Y)
				end),
				Size = writingScope:Spring(textBounds, 20, 0.8),
				
				TextWrapped = true,
				RichText = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				
				BackgroundColor3 = writingScope:Computed(function(use: Fusion.Use)
					return use(clippingOtherMessage) and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
				end),
				
				[OnChange("TextBounds")] = function()
					local bounds = textBox.TextBounds
					textBounds:set(UDim2.fromOffset(200, bounds.Y))
					checkClipping()
					
					text = textBox.Text
				end,
				
				[Children] = {
					writingScope:New "UICorner" { CornerRadius = UDim.new(0.1) },
				}
			}
			checkClipping()
			
			table.insert(writingScope, textBox.FocusLost:Connect(function(_, input)
				if input.KeyCode == Enum.KeyCode.Return then
					service:InteractAttempt("MessageBoards", "SubmitMessageAttempt", pos, peek(textBounds), text):andThen(function(success: boolean)
						if not success then
							writingScope:doCleanup()
							return
						end
						
					end)
				else
					writingScope:doCleanup()
				end
			end))
			
			--textBox:CaptureFocus()
		end
	end)
	
	mouse.Move:Connect(function()
		for _, screenGui: ScreenGui in surfaceGuiContainer:GetChildren() do
			local GuiParentPart = screenGui.Adornee
			local TopLeftCFrame = GuiParentPart.CFrame * CFrame.new(GuiParentPart.Size.X / 2, GuiParentPart.Size.Y / 2, GuiParentPart.Size.Z / 2)
			local MouseDistanceFromTopLeft = TopLeftCFrame.Position - mouse.Hit.Position
			local RelativeLocation = Vector2.new(math.abs(MouseDistanceFromTopLeft.X) * screenGui.PixelsPerStud, math.abs(MouseDistanceFromTopLeft.Y) * screenGui.PixelsPerStud)
			
			if not surfaceMousePositions[screenGui] then
				surfaceMousePositions[screenGui] = scope:Value(RelativeLocation)
			end
			
			surfaceMousePositions[screenGui]:set(RelativeLocation)
			
			for _, object in ipairs(screenGui:GetChildren()) do
				if not object:IsA("GuiObject") or object.Name == "Backdrop" then
					continue
				end
				pointObstructed:set((
					RelativeLocation.X >= object.AbsolutePosition.X 
						and RelativeLocation.X <= object.AbsolutePosition.X + object.AbsoluteSize.X
						and RelativeLocation.Y >= object.AbsolutePosition.Y
						and RelativeLocation.Y <= object.AbsolutePosition.Y + object.AbsoluteSize.Y
				))
			end
		end
	end)
	
	
	mouse.Button1Down:Connect(function()
		writingSurfaceGui:set(nil)
	end)
end

MessageBoards.taggedObjectAdded = function(taggedObject: Instance)
	local tempScope = Fusion:scoped()
	tempScopes[taggedObject] = tempScope
	
	local newboardMessages = peek(boardMessages)
	newboardMessages[taggedObject] = tempScope:Value({})
	boardMessages:set(newboardMessages)
	
	tempScope:Observer(writingSurfaceGui):onBind(function()
		if peek(writingSurfaceGui) then
			taggedObject:RemoveTag(Tooltip.OBJECT_TAG)
		else
			taggedObject:AddTag(Tooltip.OBJECT_TAG)
		end
	end)
	
	local clickDetector: ClickDetector = taggedObject:FindFirstChildWhichIsA("ClickDetector")
	tempScope:Hydrate(clickDetector) {
		MaxActivationDistance = tempScope:Computed(function(use: Fusion.Use)
			return use(writingSurfaceGui) and 0 or 32
		end),
		[OnEvent("MouseClick")] = function()
			if peek(pointObstructed) or peek(writingSurfaceGui) then
				return
			end
			writingSurfaceGui:set(boardSurfaceGuis[taggedObject])
		end
	}
end

MessageBoards.taggedObjectRemoved = function(taggedObject: Instance)
	local tempScope = tempScopes[taggedObject]
	if tempScope then
		tempScope:doCleanup()
	end
end

return MessageBoards