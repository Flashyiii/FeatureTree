local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local e = React.createElement

local capturedRoots = {}
for _, module in ReplicatedStorage.Source.Features:GetDescendants() do
	if module:IsA("ModuleScript") and module.Name:match("Root") and module ~= script then
		capturedRoots[module.Name] = require(module)
	end
end

local function RootUI()
	return e(
		React.Fragment,
		nil,
		Sift.Dictionary.map(capturedRoots, function(rootModule, rootName)
			return e(rootModule, { Name = rootName })
		end),
		{}
	)
end

return RootUI
