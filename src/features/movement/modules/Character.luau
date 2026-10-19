local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCS = require(ReplicatedStorage.Packages.wcs)
local Config = require(ReplicatedStorage.Source.Features.Movement.Config)
local Camera = require(ReplicatedStorage.Source.Features.Movement.Modules.Camera)
local Effects = require(ReplicatedStorage.Source.Features.Movement.Modules.Effects)
local Traversal = require(ReplicatedStorage.Source.Features.Movement.Modules.Traversal)

local Character = {}
Character.__index = Character
local Characters: { [Model]: Character } = {}

function Character.new(character: WCS.Character)
	local model = character.Instance
	local root = model:WaitForChild("HumanoidRootPart")
	local humanoid = character.Humanoid
	local params = Traversal.params(model)
	local effects = Effects.new(root, humanoid:WaitForChild("Animator"))
	local self = setmetatable({
		Model = model, WCS = character, Root = root, Humanoid = humanoid, Params = params,
		Effects = effects, Traversal = Traversal.new(root, params, effects), Camera = Camera.new(root, params),
		Grounded = true, AirJumpUsed = false, HoldingSlide = false, Pending = {},
		LandingSpeed = 0, Destroyed = false, Animate = nil,
	}, Character)
	Characters[model] = self

	local function disableAnimate(child: Instance)
		if child.Name == "Animate" and child:IsA("LocalScript") then
			self.Animate = child
			child.Enabled = false
			for _, track in humanoid.Animator:GetPlayingAnimationTracks() do
				track:Stop(0)
			end
		end
	end
	for _, child in model:GetChildren() do
		disableAnimate(child)
	end
	self.AnimateConnection = model.ChildAdded:Connect(disableAnimate)
	self.JumpingEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	return self
end

function Character.get(model: Model): Character?
	return Characters[model]
end

function Character.request(self: Character, name: string, parameter: string?)
	local skill = self.WCS:GetSkillFromString("Movement" .. name)
	if not skill then
		return
	end
	local state = skill:GetState()
	if state.IsActive or state.Debounce then
		return
	end
	local now = os.clock()
	if self.Pending[name] and now < self.Pending[name] then
		return
	end
	if not skill:ShouldStart(parameter) then
		return
	end
	self.Pending[name] = now + Config.RequestTimeout
	if parameter then
		skill:Start(parameter)
	else
		skill:Start()
	end
end

function Character.endTraversal(self: Character)
	local mode = self.Traversal.Mode
	self.Traversal:stop()
	if mode then
		self.WCS:GetSkillFromString("Movement" .. mode):End()
	end
end

function Character.jumpKind(self: Character): string?
	if self.Traversal.Mode == "Slide" then
		return "Slide"
	elseif self.Traversal.Mode == "WallRun" then
		return self.Traversal.Side
	elseif self.Grounded then
		return "Ground"
	elseif not self.AirJumpUsed then
		return "Double"
	end
	return nil
end

function Character.jump(self: Character, kind: string)
	self.Pending.Jump = nil
	self.AirJumpUsed = kind == "Double"
	self.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	self.Traversal:jump(kind, self.Humanoid.WalkSpeed / Config.WalkSpeed)
	if kind == "Slide" then
		self.Camera:boost("SlideJump")
	elseif kind == "Left" or kind == "Right" then
		self.Camera:boost("WallJump")
	end
end

function Character.update(self: Character, delta: number)
	if self.Humanoid.Health <= 0 or self.WCS:IsDestroyed() then
		return
	end
	local floor = Traversal.floor(self.Root, self.Params, Config.Jump.GroundDistance)
	local grounded = self.Humanoid.FloorMaterial ~= Enum.Material.Air
		or floor ~= nil and self.Root.AssemblyLinearVelocity.Y <= Config.Jump.GroundVelocityTolerance
	if grounded and not self.Grounded then
		self.AirJumpUsed = false
		if not self.HoldingSlide then
			self.Effects:land(self.LandingSpeed)
		end
	end
	self.Grounded = grounded
	self.LandingSpeed = self.Root.AssemblyLinearVelocity.Magnitude
	local scale = self.Humanoid.WalkSpeed / Config.WalkSpeed
	if self.WCS.DisableSkills or self.Model:GetAttribute("MovementDisabled") then
		self:endTraversal()
	elseif not self.Traversal:update(delta, self.Humanoid.MoveDirection, scale) then
		self:endTraversal()
	end

	if not self.Traversal.Mode and self.Traversal.BoostRemaining == 0 then
		if self.HoldingSlide and grounded then
			self:request("Slide")
		elseif not Traversal.floor(self.Root, self.Params, Config.WallRun.GroundDistance) then
			for _, side in { "Left", "Right" } do
				if Traversal.wall(self.Root, self.Params, side) then
					self:request("WallRun", side)
					break
				end
			end
		end
	end

	local autoRotate = self.WCS:GetAppliedProps().AutoRotate
	self.Humanoid.AutoRotate = autoRotate and not self.Camera.Controller.Enabled and self.Traversal.Mode == nil
	if autoRotate then
		self.Camera:face(delta, self.Humanoid.MoveDirection, self.Traversal.Mode)
	end
	local speed = (self.Root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
	self.Effects:update(grounded, self.Humanoid.MoveDirection.Magnitude > 0.1, speed)
end

function Character.destroy(self: Character)
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	Characters[self.Model] = nil
	self.AnimateConnection:Disconnect()
	self.Traversal:destroy()
	self.Effects:destroy()
	self.Camera:destroy()
	self.Humanoid.AutoRotate = self.WCS:GetAppliedProps().AutoRotate
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, self.JumpingEnabled)
	if self.Animate then
		self.Animate.Enabled = true
	end
end

export type Character = typeof(Character) & {
	Model: Model, WCS: WCS.Character, Root: BasePart, Humanoid: Humanoid, Params: RaycastParams,
	Effects: Effects.Effects, Traversal: Traversal.Traversal, Camera: Camera.Camera,
	Grounded: boolean, AirJumpUsed: boolean, HoldingSlide: boolean, Pending: { [string]: number },
	LandingSpeed: number, Destroyed: boolean, Animate: LocalScript?,
	AnimateConnection: RBXScriptConnection, JumpingEnabled: boolean,
}

return Character
