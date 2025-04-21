-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Containers --
local Assets = ReplicatedStorage:WaitForChild("Assets")
local GuiTemplates = Assets:FindFirstChild("Gui"):FindFirstChild("Templates")

local RightMenu = {}

RightMenu.Profile = {
	MAX_BIO_CHARACTERS = 300,
}

RightMenu.Servers = {
	DEFAULT_FILTER_TYPE = "Descending",
	
	SERVER_TEMPLATE = GuiTemplates:FindFirstChild("Server"),
	PFP_PREVIEW_TEMPLATE = GuiTemplates:FindFirstChild("PfpServerPreview"),
	MAX_PFP_PREVIEWS = 5,
}

return RightMenu