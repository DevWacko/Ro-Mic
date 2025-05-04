local function FitViewport(object: Model | BasePart, viewport: ViewportFrame, angle: CFrame?)
	local cf, size = object:GetBoundingBox()
	
	angle = angle or CFrame.Angles(0, math.rad(180), 0)
	
	size = angle:VectorToObjectSpace(size)
	local sizeX, sizeY, sizeZ = math.abs(size.X), math.abs(size.Y), math.abs(size.Z)
	
	local frameSize = viewport.AbsoluteSize.X
	
	local cam = Instance.new("Camera")
	local h = (sizeY / (math.tan(math.rad(cam.FieldOfView / 2)) * 2)) + (sizeZ / 2)
	
	local frameX = (sizeX > sizeY and frameSize or (frameSize * (sizeX / sizeY)))
	local frameY = (sizeY > sizeX and frameSize or (frameSize * (sizeY / sizeX)))
	
	cam.CFrame = cf * angle * CFrame.new(0, 0, h)
	cam.Parent = viewport
	object.Parent = cam
	viewport.CurrentCamera = cam
end
return FitViewport