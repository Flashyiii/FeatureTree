local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)

local capturedRoots = {}
for _, module in ReplicatedStorage.Source.Features:GetDescendants() do
	if module:IsA("ModuleScript") and module.Name:match("Root") and module ~= script then
		capturedRoots[module.Name] = require(module)
	end
end

local function RootUI()
	local roots = {}
	for rootName, rootModule in pairs(capturedRoots) do
		table.insert(roots, rootModule({ Name = rootName }))
	end
	return roots
end

return RootUI
