-- Services --
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

-- Containers --
local ExPackages = ReplicatedStorage.ExPackages

-- Modules --
local Tooltip = require(ReplicatedStorage.Source.Data.Gui.Tooltip)

local Fusion = require(ExPackages.Fusion)
local Knit = require(ExPackages.Knit)

local Children, OnEvent, OnChange = Fusion.Children, Fusion.OnEvent, Fusion.OnChange
local peek = Fusion.peek

local MessageBoardsData = require(ReplicatedStorage.Source.Data.Interacting.MessageBoards)

-- Main Module --
local MessageBoards = {
	Tag = "MessageBoard",
}

-- Types --
type Message = {
	boardId: string,
	
	position: UDim2,
	size: UDim2,
	text: string,
}

-- Local --
local player = Players.LocalPlayer

local mouse = player:GetMouse()

local controller
local service

local scope: Fusion.Scope = Fusion:scoped()
local writingScope: Fusion.Scope = Fusion:scoped()
local selectScope: Fusion.Scope = Fusion:scoped()

local boardMessages: Fusion.Value<{ [string]: Fusion.Value<{ [string]: Message }> }> = scope:Value({})
local boardSurfaceGuis: { [string]: ScreenGui } = {}

local selectedSurfaceGui: Fusion.Value<SurfaceGui?> = scope:Value(nil)
local selectionBox: Fusion.Value<Frame?> = scope:Value(nil)
local savedSelectedSurfaceGui: SurfaceGui?

local writingMessage: Fusion.Value<boolean> = scope:Value(false)
local canStartWrite: Fusion.Value<boolean> = scope:Value(false)
local canSubmit: Fusion.Value<boolean> = scope:Value(false)

local surfaceMousePosition: Fusion.Value<Boolean> = scope:Value(UDim2.new())

local tempScopes: { [Instance]: Fusion.Scope } = {}

local streamingBoardParts: Fusion.Value<{ [string]: Instance }> = scope:Value({})

function collidesWith(position: Vector2, size: Vector2, gui2)
    local gui1_topLeft = position
	local gui1_bottomRight = gui1_topLeft + size
	local gui2_topLeft = gui2.AbsolutePosition
    local gui2_bottomRight = gui2_topLeft + gui2.AbsoluteSize
	return ((gui1_topLeft.x < gui2_bottomRight.x and gui1_bottomRight.x > gui2_topLeft.x) and (gui1_topLeft.y < gui2_bottomRight.y and gui1_bottomRight.y > gui2_topLeft.y))
end

local function isInBounds(position: Vector2, size: Vector2, container: GuiObject): boolean
	local containerPos = container.AbsolutePosition
	local containerSize = container.AbsoluteSize

	return (
		position.X >= containerPos.X and
		position.Y >= containerPos.Y and
		position.X + size.X <= containerPos.X + containerSize.X and
		position.Y + size.Y <= containerPos.Y + containerSize.Y
	)
end

local function checkClipping(textBox: TextBox, position: Vector2, size: Vector2, screenGui: ScreenGui)
	for _, otherMessage: TextBox? in screenGui:GetChildren() do
		if not otherMessage:IsA("GuiLabel") or otherMessage == textBox then
			continue
		end
		return collidesWith(position, size, otherMessage)
	end
end

local function getTextFlexSize(text: string)
	local textSize = TextService:GetTextSize(
		text,
		MessageBoardsData.Gui.Message.FONT_SIZE,
		MessageBoardsData.Gui.Message.FONT,
		Vector2.new(200, math.huge)
	)
	local width = math.min(textSize.X, 200)

	return UDim2.new(0, width + 10, 0, textSize.Y)
end

MessageBoards.init = function()
	controller = Knit.GetController("InteractingController")
	service = Knit.GetService("InteractingService")
	
	controller:ObserveInteraction("MessageBoards", function(interaction: string, ...)
		local data = { ... }
		if interaction == "MessagesChanged" then
			local boardMessagesData = peek(boardMessages)
			for boardId: string, messageData: { [Player]: Message } in data[1] do
				if not boardMessagesData[boardId] then
					continue
				end
				boardMessagesData[boardId]:set(messageData)
			end
		end
	end)
	
	scope:Observer(selectedSurfaceGui):onChange(function()
		if peek(writingMessage) then
			return
		end
		
		selectScope:doCleanup()
		
		local surfaceGui: SurfaceGui? = peek(selectedSurfaceGui)
		if not surfaceGui then
			return
		end
		
		local clippingOtherMessage: Fusion.Value<boolean> = selectScope:Value(false)
		local outOfBounds: Fusion.Value<boolean> = selectScope:Value(false)
		
		selectScope:Computed(function(use: Fusion.Use)
			canStartWrite:set(not use(clippingOtherMessage) and not use(outOfBounds))
		end)
		
		local textBounds: Fusion.Value<UDim2> = selectScope:Value(UDim2.fromOffset(0, 0))
		selectionBox:set(selectScope:New "Frame" {
			Parent = surfaceGui,
			
			AnchorPoint = Vector2.one * 0.5,
			Position = selectScope:Tween(selectScope:Computed(function(use: Fusion.Use)
				return use(writingMessage) and use(selectionBox).Position or use(surfaceMousePosition)
			end), MessageBoardsData.Gui.Message.TWEEN_INFO),
			Size = selectScope:Spring(textBounds, 20, 0.8),
			
			BackgroundColor3 = selectScope:Tween(selectScope:Computed(function(use: Fusion.Use)
				return use(canStartWrite) and MessageBoardsData.Gui.Message.CAN_WRITE_COLOR or MessageBoardsData.Gui.Message.CANNOT_WRITE_COLOR
			end), MessageBoardsData.Gui.Message.TWEEN_INFO),
			BackgroundTransparency = 0.5,
			
			[OnChange("Position")] = function(pos: UDim2)
				local textBox = peek(selectionBox)
				local surfaceGui = peek(selectedSurfaceGui)
				if not textBox or not surfaceGui then
					canStartWrite:set(false)
					return
				end
				local bounds = getTextFlexSize(`<b>{player.Name}:</b>`)
				bounds = Vector2.new(bounds.X.Offset, bounds.Y.Offset)
				
				clippingOtherMessage:set(checkClipping(textBox, textBox.AbsolutePosition, bounds, surfaceGui))
				outOfBounds:set(not isInBounds(textBox.AbsolutePosition, bounds, surfaceGui))
			end,
			
			[Children] = {
				selectScope:New "UICorner" { CornerRadius = MessageBoardsData.Gui.Message.CORNER_RADIUS },
			}
		})
		textBounds:set(UDim2.fromOffset(20, 15))
	end)
	
	local surfaceGuiContainer: Folder = scope:New "Folder" {
		Name = "MessageBoardSurfaceGuis",
		Parent = player:WaitForChild("PlayerGui"),
		[Children] = {
			scope:ForPairs(streamingBoardParts, function(
				use: Fusion.Use,
				surfaceScope: Fusion.Scope,
				boardId: string,
				taggedObject: Instance
			)
				local messages = use(boardMessages)[boardId]
				boardSurfaceGuis[boardId] = surfaceScope:New "SurfaceGui" {
					Name = taggedObject.Name,
					Adornee = taggedObject,
					
					Brightness = 1,
					
					[Children] = {
						surfaceScope:ForPairs(messages, function(_use: Fusion.Use, messageScope: Fusion.Scope, userId: string, messageData: Message)
							local bgColor: Fusion.Value<Color3> = messageScope:Value(MessageBoardsData.Gui.Message.CAN_WRITE_COLOR)
							
							local text = `<b>{Players:GetPlayerByUserId(tonumber(userId)).Name}:</b> {messageData.text}`
							local message = messageScope:New "TextLabel" {
								Position = messageData.position,
								Size = getTextFlexSize(text),
								
								Font = MessageBoardsData.Gui.Message.FONT,
								TextSize = MessageBoardsData.Gui.Message.FONT_SIZE,
								TextWrapped = true,
								RichText = true,
								Text = text,
								
								BackgroundColor3 = messageScope:Tween(bgColor, MessageBoardsData.Gui.Message.COLOR_TWEEN_INFO),
								
								[Children] = {
									messageScope:New "UICorner" { CornerRadius = MessageBoardsData.Gui.Message.CORNER_RADIUS },
								},
							}
							bgColor:set(Color3.new(0.9, 0.9, 0.9))
							return player, message
						end),
						surfaceScope:New "Frame" {
							Name = "Backdrop",
							Size = UDim2.fromScale(1, 1),
							[OnEvent("MouseEnter")] = function()
								local surfaceGui = boardSurfaceGuis[boardId]
								selectedSurfaceGui:set(surfaceGui)
								savedSelectedSurfaceGui = surfaceGui
							end,
							[OnEvent("MouseLeave")] = function()
								selectedSurfaceGui:set(nil)
								savedSelectedSurfaceGui = nil
							end,
						},
					},
				}
				return boardId, boardSurfaceGuis[boardId]
			end)
		},
	}
	
	mouse.Move:Connect(function()
		for _, screenGui: ScreenGui in surfaceGuiContainer:GetChildren() do
			if screenGui ~= peek(selectedSurfaceGui) then
				continue
			end
			
			local GuiParentPart = screenGui.Adornee
			local TopLeftCFrame = GuiParentPart.CFrame * CFrame.new(GuiParentPart.Size.X / 2, GuiParentPart.Size.Y / 2, GuiParentPart.Size.Z / 2)
			local MouseDistanceFromTopLeft = TopLeftCFrame.Position - mouse.Hit.Position
			local RelativeLocation = Vector2.new(math.abs(MouseDistanceFromTopLeft.X) * screenGui.PixelsPerStud, math.abs(MouseDistanceFromTopLeft.Y) * screenGui.PixelsPerStud)
			
			surfaceMousePosition:set(UDim2.fromOffset(RelativeLocation.X, RelativeLocation.Y))
		end
	end)
	
	
	mouse.Button1Down:Connect(function()
		writingScope:doCleanup()
		writingMessage:set(false)
	end)
end

MessageBoards.taggedObjectAdded = function(taggedObject: Instance)
	local newStreamingBoardParts = peek(streamingBoardParts)
	newStreamingBoardParts[taggedObject:GetAttribute("Id")] = taggedObject
	streamingBoardParts:set(newStreamingBoardParts)
	
	local tempScope = Fusion:scoped()
	tempScopes[taggedObject] = tempScope
	
	local newboardMessages = peek(boardMessages)
	newboardMessages[taggedObject:GetAttribute("Id")] = tempScope:Value({})
	boardMessages:set(newboardMessages)
	
	tempScope:Observer(writingMessage):onBind(function()
		if peek(writingMessage) then
			taggedObject:RemoveTag(Tooltip.OBJECT_TAG)
		else
			taggedObject:AddTag(Tooltip.OBJECT_TAG)
		end
	end)
	
	local clickDetector: ClickDetector = taggedObject:FindFirstChildWhichIsA("ClickDetector")
	tempScope:Hydrate(clickDetector) {
		MaxActivationDistance = tempScope:Computed(function(use: Fusion.Use)
			return use(writingMessage) and 0 or 32
		end),
		[OnEvent("MouseClick")] = function()
			local surfaceGui = peek(selectedSurfaceGui)
			if not peek(canStartWrite) or not surfaceGui then
				return
			end
			
			writingMessage:set(true)
			selectScope:doCleanup()
			
			local clippingOtherMessage: Fusion.Value<boolean> = writingScope:Value(false)
			local outOfBounds: Fusion.Value<boolean> = writingScope:Value(false)
			
			writingScope:Computed(function(use: Fusion.Use)
				canSubmit:set(not use(clippingOtherMessage) and not use(outOfBounds))
			end)
			
			local bgColor: Fusion.Value<Color3> = writingScope:Value(Color3.new())
			local size: Fusion.Value<Udim2> = writingScope:Value(UDim2.fromOffset(10, 15))
			
			writingScope:Observer(canSubmit):onBind(function()
				bgColor:set(peek(canSubmit) and MessageBoardsData.Gui.Message.CAN_WRITE_COLOR or MessageBoardsData.Gui.Message.CANNOT_WRITE_COLOR)
			end)
			
			local pos = peek(surfaceMousePosition)
			local text = ""
			
			local shown: Fusion.Value<boolean> = writingScope:Value(true)
			local canEdit: Fusion.Value<boolean> = writingScope:Value(true)
			
			local textBox: TextBox
			textBox = writingScope:New "TextBox" {
				Parent = surfaceGui,
				
				Position = pos,
				Size = size,--writingScope:Spring(size, 20, 0.8),
				
				Font = MessageBoardsData.Gui.Message.FONT,
				TextSize = MessageBoardsData.Gui.Message.FONT_SIZE,
				TextEditable = canEdit,
				TextWrapped = true,
				RichText = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				TextTransparency = writingScope:Tween(writingScope:Computed(function(use: Fusion.Use)
					return use(shown) and 0.2 or 1
				end),  MessageBoardsData.Gui.Message.TWEEN_INFO),
				
				BackgroundColor3 = writingScope:Tween(bgColor,  MessageBoardsData.Gui.Message.COLOR_TWEEN_INFO),
				BackgroundTransparency = writingScope:Tween(writingScope:Computed(function(use: Fusion.Use)
					return use(shown) and 0.5 or 1
				end),  MessageBoardsData.Gui.Message.TWEEN_INFO),
				
				[OnChange("Text")] = function(newText)
					size:set(getTextFlexSize(newText))
					text = textBox.Text
				end,
				[OnChange("Size")] = function()
					local bounds = getTextFlexSize(`<b>{player.Name}:</b> {textBox.Text}`)
					bounds = Vector2.new(bounds.X.Offset, bounds.Y.Offset)
					
					clippingOtherMessage:set(checkClipping(textBox, textBox.AbsolutePosition, bounds, surfaceGui))
					outOfBounds:set(not isInBounds(textBox.AbsolutePosition, bounds, surfaceGui))
				end,
				
				[Children] = {
					writingScope:New "UICorner" { CornerRadius = MessageBoardsData.Gui.Message.CORNER_RADIUS },
				}
			}
			textBox:CaptureFocus()
			
			local function cleanup()
				textBox:ReleaseFocus()
				
				writingMessage:set(false)
				shown:set(false)
				canEdit:set(false)
				
				if savedSelectedSurfaceGui then
					selectedSurfaceGui:set(nil)
					selectedSurfaceGui:set(savedSelectedSurfaceGui)
				end
				
				task.delay(MessageBoardsData.Gui.Message.TWEEN_INFO.Time, function()
					writingScope:doCleanup()
				end)
			end
			
			table.insert(writingScope, textBox.FocusLost:Connect(function(_, input)
				if input.KeyCode == Enum.KeyCode.Return and peek(canSubmit) then
					canEdit:set(false)
					service:InteractAttempt("MessageBoards", "SubmitMessageAttempt", taggedObject:GetAttribute("Id"), pos, peek(size), text):andThen(function(success: boolean)
						if success then
							bgColor:set(MessageBoardsData.Gui.Message.MESSAGE_BG_COLOR)
						end
						cleanup()
					end)
				else
					cleanup()
				end
			end))
		end
	}
end

MessageBoards.taggedObjectRemoved = function(taggedObject: Instance)
	local tempScope = tempScopes[taggedObject]
	if tempScope then
		tempScope:doCleanup()
	end
	
	local id = taggedObject:GetAttribute("Id")
	if streamingBoardParts[id] then
		streamingBoardParts[id] = nil
	end
end

return MessageBoards