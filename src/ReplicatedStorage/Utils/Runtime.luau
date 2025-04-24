local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local function loadFolder(folder: Folder, t: {}, searchCount: number, maxDeepSearch: number)
	if searchCount > maxDeepSearch then
		return t
	end
	searchCount += 1
	
	local loaded = {}
	for _, obj: Instance in folder:GetChildren() do
		if obj:IsA("ModuleScript") then
			loaded[obj.Name] = require(obj)
		elseif obj:IsA("Folder") then
			loadFolder(obj, loaded, searchCount, maxDeepSearch)
		end
	end
	t[folder.Name] = loaded
end

return function (folders: { Folder }, maxDeepSearch: number?)
	maxDeepSearch = maxDeepSearch or 0
	local searchCount = 0
	
	local loaded = {}
	for _, folder in folders do
		loadFolder(folder, loaded, searchCount, maxDeepSearch)
	end
	for folder, loadedContents in loaded do
		Knit[folder] = loadedContents
	end
end