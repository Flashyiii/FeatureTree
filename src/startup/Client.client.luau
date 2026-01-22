local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminServiceClient = require(ReplicatedStorage.Source.Features.Admin.AdminServiceClient)
local MountUI = require(script.Parent.MountUI)
MountUI()

AdminServiceClient:init()
