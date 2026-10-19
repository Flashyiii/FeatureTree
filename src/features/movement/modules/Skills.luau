local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WCS = require(ReplicatedStorage.Packages.wcs)
local Config = require(ReplicatedStorage.Source.Features.Movement.Config)
local Character = require(ReplicatedStorage.Source.Features.Movement.Modules.Character)
local Traversal = require(ReplicatedStorage.Source.Features.Movement.Modules.Traversal)

local Jump = WCS.RegisterSkill("MovementJump")
local Slide = WCS.RegisterHoldableSkill("MovementSlide")
local WallRun = WCS.RegisterHoldableSkill("MovementWallRun")
local Dash = WCS.RegisterSkill("MovementDash")

local function configure(self: WCS.Skill)
	self.CheckOthersActive = false
	self.CheckedByOthers = false
	self.CheckClientState = true
end

local function canMove(self: WCS.Skill): boolean
	return self.Character.Humanoid.Health > 0
		and self.Character.Humanoid.WalkSpeed > 0
		and not self.Character.DisableSkills
		and not self.Character.Instance:GetAttribute("MovementDisabled")
end

local function active(self: WCS.Skill, name: string): boolean
	return self.Character:GetSkillFromString("Movement" .. name):GetState().IsActive
end

local function surface(self: WCS.Skill, distance: number): RaycastResult?
	local root = self.Character.Instance.HumanoidRootPart
	return Traversal.floor(root, Traversal.params(self.Character.Instance), distance)
end

function Jump:OnConstruct()
	configure(self)
	self.AirJumpUsed = false
	self.ParamValidators = { function(kind)
		return kind == "Ground" or kind == "Double" or kind == "Slide" or kind == "Left" or kind == "Right"
	end }
end

function Jump:ShouldStart(kind: string): boolean
	if not canMove(self) then
		return false
	end
	if kind == "Slide" then
		return active(self, "Slide")
	elseif kind == "Left" or kind == "Right" then
		local wallRun = self.Character:GetSkillFromString("MovementWallRun")
		local state = wallRun:GetState()
		return state.IsActive and state.StarterParams[1] == kind
	elseif kind == "Ground" then
		return self.Character.Humanoid.FloorMaterial ~= Enum.Material.Air
			or surface(self, Config.Jump.GroundDistance) ~= nil
	elseif kind == "Double" then
		local movement = Character.get(self.Character.Instance)
		local used = if RunService:IsClient() then not movement or movement.AirJumpUsed else self.AirJumpUsed
		return not used and not surface(self, Config.Jump.GroundDistance)
	end
	return false
end

function Jump:OnStartServer(kind: string)
	self.AirJumpUsed = kind == "Double"
	self.Character:GetSkillFromString("MovementSlide"):End()
	self.Character:GetSkillFromString("MovementWallRun"):End()
	self:ApplyCooldown(if kind == "Double" or kind == "Left" or kind == "Right"
		then Config.Jump.AirCooldown else Config.Jump.Cooldown)
	-- Keep the active state visible to WCS's deferred replication.
	task.wait(Config.Jump.ActiveTime)
end

function Jump:OnStartClient(kind: string)
	local movement = Character.get(self.Character.Instance)
	if movement then
		movement:jump(kind)
	end
end

function Slide:OnConstruct()
	configure(self)
	self.ParamValidators = {}
end

function Slide:OnConstructServer()
	self:SetMaxHoldTime(Config.Slide.Duration)
end

function Slide:ShouldStart(): boolean
	return canMove(self) and not active(self, "WallRun") and surface(self, Config.Slide.GroundDistance) ~= nil
end

function Slide:OnStartServer()
	self.Character.Instance:SetAttribute("Sliding", true)
end

function Slide:OnEndServer()
	self.Character.Instance:SetAttribute("Sliding", false)
	self:ApplyCooldown(Config.Slide.Cooldown)
end

function Slide:OnStartClient()
	local movement = Character.get(self.Character.Instance)
	if not movement then
		return
	end
	movement.Pending.Slide = nil
	if movement.HoldingSlide then
		movement.Traversal:slide()
	else
		self:End()
	end
end

function Slide:OnEndClient()
	local movement = Character.get(self.Character.Instance)
	if movement and movement.Traversal.Mode == "Slide" then
		movement.Traversal:stop()
	end
end

function WallRun:OnConstruct()
	configure(self)
	self.ParamValidators = { function(side)
		return side == "Left" or side == "Right"
	end }
end

function WallRun:OnConstructServer()
	self:SetMaxHoldTime(Config.WallRun.Duration)
end

function WallRun:ShouldStart(side: string): boolean
	if not canMove(self) or active(self, "Slide") or active(self, "Jump") then
		return false
	end
	if surface(self, Config.WallRun.GroundDistance) then
		return false
	end
	local root = self.Character.Instance.HumanoidRootPart
	local params = Traversal.params(self.Character.Instance)
	return not workspace:Raycast(root.Position, root.CFrame.LookVector, params)
		and Traversal.wall(root, params, side) ~= nil
end

function WallRun:OnStartServer()
	self.Character:GetSkillFromString("MovementJump").AirJumpUsed = false
	self.Character.Instance:SetAttribute("WallRunning", true)
end

function WallRun:OnEndServer()
	self.Character.Instance:SetAttribute("WallRunning", false)
	self:ApplyCooldown(Config.WallRun.Cooldown)
end

function WallRun:OnStartClient(side: string)
	local movement = Character.get(self.Character.Instance)
	if not movement then
		return
	end
	movement.Pending.WallRun = nil
	if movement.Traversal:wallRun(side) then
		movement.AirJumpUsed = false
	else
		self:End()
	end
end

function WallRun:OnEndClient()
	local movement = Character.get(self.Character.Instance)
	if movement and movement.Traversal.Mode == "WallRun" then
		movement.Traversal:stop()
	end
end

function Dash:OnConstruct()
	configure(self)
	self.ParamValidators = {}
end

function Dash:ShouldStart(): boolean
	return canMove(self)
end

function Dash:OnStartServer()
	self.Character:GetSkillFromString("MovementSlide"):End()
	self.Character:GetSkillFromString("MovementWallRun"):End()
	self:ApplyCooldown(Config.Dash.Cooldown)
	task.wait(Config.Dash.Duration)
end

function Dash:OnStartClient()
	local movement = Character.get(self.Character.Instance)
	if movement then
		movement.Pending.Dash = nil
		movement.Traversal:dash(workspace.CurrentCamera.CFrame.LookVector)
		movement.Camera:boost("Dash")
	end
end

return { Jump = Jump, Slide = Slide, WallRun = WallRun, Dash = Dash }
