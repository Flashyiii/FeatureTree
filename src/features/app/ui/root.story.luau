local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)
local RootUI = require(script.Parent.RootUI)

return function(parent)
	local mountCleanup = Vide.mount(RootUI, parent)
	
	return function()
		mountCleanup()
	end
end
