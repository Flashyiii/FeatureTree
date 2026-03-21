local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)
local RootUI = require(ReplicatedStorage.Source.Features.App.UI.RootUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

return function()
	local container = Instance.new("ScreenGui")
	container.Name = "VideUI"
	container.IgnoreGuiInset = true
	container.ResetOnSpawn = false
	container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	container.ClipToDeviceSafeArea = false
	container.Parent = playerGui
	
	Vide.mount(RootUI, container)
end
