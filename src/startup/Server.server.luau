local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ReplicatedStorage.Packages.DataService).server
local AdminServiceServer = require(ServerScriptService.Features.Admin.AdminServiceServer)
local DataTemplate = require(ReplicatedStorage.Source.Game.Items.DataTemplate)

_G.ResetData = true
_G.Beta = true
_G.Debug = true
_G.Version = "1.0.0"

local ProfileStoreIndex = "Production"

if game:GetService("RunService"):IsStudio() then
	ProfileStoreIndex = "Development"
end

DataService:init({
	template = DataTemplate,
	profileStoreIndex = ProfileStoreIndex,
	useMock = false,
	resetData = _G.ResetData,
})

function DataService:onPlayerInit(player: Player, data): ()
	local Information = data.Information

	if Information.FirstJoined == 0 then
		Information.JoinedBeta = _G.Beta
		Information.FirstJoined = os.time()
		Information.Version = _G.Version
	end

	Information.LastJoined = os.time()
	Information.TimesSeen += 1

	player:SetAttribute("ProfileLoaded", true)
end

DataService:addPlayerRemovingCallback(function(player: Player, data)
	warn("Disconnecting Player : ", player)
	local Information = data.Information
	Information.PlayTime += os.time() - Information.LastJoined
end)

AdminServiceServer:init()
