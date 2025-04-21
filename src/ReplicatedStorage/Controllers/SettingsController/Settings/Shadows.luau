-- Main Module --
local Shadows = {}

-- Local --
local con: RBXScriptConnection?

local modifiedParts: { [number]: BasePart } = {}

Shadows.valueSet = function(toggled: boolean)
	if toggled and con then
		con:Disconnect()
		for _, p in modifiedParts do
			if not p then
				continue
			end
			p.CastShadow = true
		end
	end
	if not toggled then
		local function managePart(part)
			if not part:IsA("BasePart") then
				return
			end
			if not part.CastShadow then
				return
			end
			part.CastShadow = false
			table.insert(modifiedParts, part)
		end
		con = workspace.DescendantAdded:Connect(managePart)
		for _, obj in workspace:GetDescendants() do
			managePart(obj)
		end
	end
end

return Shadows