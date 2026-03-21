local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminServiceClient = {}

local conch = require(ReplicatedStorage.Packages.Conch)
local ui = require(ReplicatedStorage.Packages.ConchUI)

function AdminServiceClient.init(self: AdminServiceClient)
	conch.initiate_default_lifecycle()
	ui.bind_to(Enum.KeyCode.F4)
end

export type AdminServiceClient = typeof(AdminServiceClient) & {}

return AdminServiceClient
