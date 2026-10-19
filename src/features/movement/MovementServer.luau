local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Networker = require(ReplicatedStorage.Packages.Networker)
local WCS = require(ReplicatedStorage.Packages.wcs)
local Config = require(ReplicatedStorage.Source.Features.Movement.Config)
local Skills = require(ReplicatedStorage.Source.Features.Movement.Modules.Skills)

local MovementServer = {
	Characters = {} :: { [Model]: { Character: WCS.Character, Cleanup: Janitor.Janitor } },
	Players = {} :: { [Player]: Janitor.Janitor },
}

function MovementServer.init(self: MovementServer)
	self.Cleanup = Janitor.new()
	self.Network = Networker.server.new("Movement")
	self.Handler = WCS.CreateServer()
	self.Handler:Start()
	self.Cleanup:Add(Players.PlayerAdded:Connect(function(player)
		self:addPlayer(player)
	end))
	self.Cleanup:Add(Players.PlayerRemoving:Connect(function(player)
		self:removePlayer(player)
	end))
	for _, player in Players:GetPlayers() do
		self:addPlayer(player)
	end
end

function MovementServer.addPlayer(self: MovementServer, player: Player)
	local cleanup = Janitor.new()
	self.Players[player] = cleanup
	cleanup:Add(player.CharacterAdded:Connect(function(model)
		self:addCharacter(player, model)
	end))
	cleanup:Add(player.CharacterRemoving:Connect(function(model)
		self:removeCharacter(model)
	end))
	if player.Character then
		task.spawn(self.addCharacter, self, player, player.Character)
	end
end

function MovementServer.addCharacter(self: MovementServer, player: Player, model: Model)
	local humanoid = model:WaitForChild("Humanoid")
	model:WaitForChild("HumanoidRootPart")
	if player.Character ~= model or not self.Players[player] or self.Characters[model] then
		return
	end
	if not humanoid:FindFirstChildOfClass("Animator") then
		local animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local cleanup = Janitor.new()
	local character = WCS.Character.new(model)
	self.Characters[model] = { Character = character, Cleanup = cleanup }
	character:SetDefaultProps({ WalkSpeed = Config.WalkSpeed, JumpPower = 0, JumpHeight = 0 })
	for _, skill in Skills do
		skill.new(character)
	end
	cleanup:Add(character.SkillStarted:Connect(function(skill)
		local parameter = skill:GetState().StarterParams[1]
		self.Network:fireAllExcept(player, "effect", model, skill.Name, true, parameter, model.HumanoidRootPart.CFrame)
	end))
	cleanup:Add(character.SkillEnded:Connect(function(skill)
		self.Network:fireAllExcept(player, "effect", model, skill.Name, false)
	end))
	cleanup:Add(humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			character:GetSkillFromString("MovementJump").AirJumpUsed = false
		end
	end))
	cleanup:Add(humanoid.Died:Once(function()
		self:removeCharacter(model)
	end))
end

function MovementServer.removeCharacter(self: MovementServer, model: Model)
	local entry = self.Characters[model]
	if not entry then
		return
	end
	self.Characters[model] = nil
	entry.Cleanup:Destroy()
	entry.Character:Destroy()
	model:SetAttribute("Sliding", false)
	model:SetAttribute("WallRunning", false)
	self.Network:fireAll("effect", model, "MovementSlide", false)
	self.Network:fireAll("effect", model, "MovementWallRun", false)
end

function MovementServer.removePlayer(self: MovementServer, player: Player)
	if player.Character then
		self:removeCharacter(player.Character)
	end
	self.Players[player]:Destroy()
	self.Players[player] = nil
end

function MovementServer.destroy(self: MovementServer)
	self.Cleanup:Destroy()
	for player in self.Players do
		self:removePlayer(player)
	end
	self.Network:destroy()
end

export type MovementServer = typeof(MovementServer) & {
	Cleanup: Janitor.Janitor, Network: Networker.Server, Handler: WCS.Server,
}

return MovementServer
