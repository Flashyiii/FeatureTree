local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)

local source = Vide.source
local cleanup = Vide.cleanup

return function()
	local viewportSize = source(workspace.CurrentCamera.ViewportSize)

	local conn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		viewportSize(workspace.CurrentCamera.ViewportSize)
	end)

	cleanup(conn)

	return viewportSize
end
