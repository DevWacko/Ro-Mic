local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local function manageFriendsInvite(scope, mainMenu: Frame)
	local PlayerController = Knit.GetController("PlayerController")
	
	table.insert(scope, mainMenu:FindFirstChild("Contents").Menu:FindFirstChild("InviteFriends"):FindFirstChild("InviteFriends").MouseButton1Click:Connect(function()
		PlayerController:PromptFriendsInvite()
	end))
end

return manageFriendsInvite