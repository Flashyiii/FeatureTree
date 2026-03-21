local AdminServiceServer = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local dataservice = require(ReplicatedStorage.Packages.DataService).server
local conch = require(ReplicatedStorage.Packages.Conch)

conch.initiate_default_lifecycle()
conch.set_role_permissions("admin", "use-capes", "use-server-command")

local super_admins = {
	"itzFlashyiii",
}

function AdminServiceServer.init(self: AdminServiceServer): ()
	self:loadCommands()
	for _, player in Players:GetPlayers() do
		self:addPlayer(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:addPlayer(player)
	end)
end

function AdminServiceServer.loadCommands(self: AdminServiceServer): ()
	for _, v in pairs(ReplicatedStorage.Source.Features.Admin.Modules:GetDescendants()) do
		if v:IsA("ModuleScript") then
			require(v)
		end
	end
end

function AdminServiceServer.setRole(self: AdminServiceServer, player: Player): ()
	dataservice:waitForData(player)
	if RunService:IsStudio() then
		return dataservice:set(player, { "Group" }, "super-user", true)
	else
		for _, v in pairs(super_admins) do
			if v == player.Name then
				dataservice:set(player, { "Group" }, "super-user", true)
			end
		end
	end
end

function AdminServiceServer.addPlayer(self: AdminServiceServer, player: Player): ()
	self:setRole(player)

	local user = conch.get_user(player)
	local role = dataservice:get(player, { "Group" })
	conch.give_roles(user, role)
end

export type AdminServiceServer = typeof(AdminServiceServer) & {}

return AdminServiceServer
