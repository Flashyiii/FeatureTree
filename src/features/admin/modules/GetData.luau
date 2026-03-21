local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local conch = require(ReplicatedStorage.Packages.Conch)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local GetData = {}

conch.register("GetData", {
	description = "Get Players Datastore Data",
	permissions = { "GetData" },
	arguments = function()
		return conch.args.player("player", "Player Name")
	end,

	callback = function(player)
		local profile = DataService:getProfile(player)
		warn(profile.Data)
	end,
})

return GetData
