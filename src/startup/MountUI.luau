local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local React = require(ReplicatedStorage.Packages.React)
local RootUI = require(ReplicatedStorage.Source.Features.App.UI.RootUI)
local ReactRoblox = require(game:GetService("ReplicatedStorage").Packages.ReactRoblox)
local e = React.createElement

return function()
	local container = Instance.new("ScreenGui")
	container.Name = "React"
	container.IgnoreGuiInset = true
	container.ResetOnSpawn = false
	container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	container.ClipToDeviceSafeArea = false
	container.Parent = playerGui
	local root = ReactRoblox.createRoot(container)
	local app = e(RootUI)
	root:render(app)
end
