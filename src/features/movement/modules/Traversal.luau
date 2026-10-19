local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Source.Features.Movement.Config)
local Effects = require(ReplicatedStorage.Source.Features.Movement.Modules.Effects)
local VFX = require(ReplicatedStorage.Source.Features.Movement.Modules.VFX)
local Horizontal = Vector3.new(1, 0, 1)

local Traversal = {}
Traversal.__index = Traversal

local function alongWall(root: BasePart, normal: Vector3): Vector3
	local tangent = Vector3.yAxis:Cross(normal).Unit
	return if tangent:Dot(root.CFrame.LookVector) < 0 then -tangent else tangent
end

function Traversal.params(model: Model): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	params.CollisionGroup = model.HumanoidRootPart.CollisionGroup
	params.RespectCanCollide = true
	return params
end

function Traversal.floor(root: BasePart, params: RaycastParams, distance: number): RaycastResult?
	local hit = workspace:Raycast(root.Position, -Vector3.yAxis * distance, params)
	return if hit and hit.Normal.Y > 0 then hit else nil
end

function Traversal.wall(root: BasePart, params: RaycastParams, side: string): RaycastResult?
	local sign = if side == "Left" then -1 else 1
	local hit = workspace:Raycast(root.Position, root.CFrame.RightVector * sign * Config.WallRun.Distance, params)
	if hit and math.abs(hit.Normal.Y) <= Config.WallRun.MaxNormalY then
		return hit
	end
	return nil
end

function Traversal.new(root: BasePart, params: RaycastParams, effects: Effects.Effects)
	local attachment = Instance.new("Attachment")
	attachment.Name = "MovementAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.ForceLimitsEnabled = true
	velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	velocity.MaxForce = root.AssemblyMass * Config.Physics.Acceleration
	velocity.Enabled = false
	velocity.Parent = root
	local orientation = Instance.new("AlignOrientation")
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0 = attachment
	orientation.Responsiveness = Config.Physics.Responsiveness
	orientation.MaxTorque = Config.Physics.MaxTorque
	orientation.MaxAngularVelocity = Config.Physics.MaxAngularVelocity
	orientation.Enabled = false
	orientation.Parent = root
	return setmetatable({
		Root = root, Model = root.Parent, Params = params, Effects = effects,
		Attachment = attachment, Velocity = velocity, Orientation = orientation,
		Mode = nil, Elapsed = 0, BoostRemaining = 0, Side = "Left",
		WallNormal = Vector3.zero, WallTangent = Vector3.zero, WallPosition = Vector3.zero,
	}, Traversal)
end

function Traversal.stop(self: Traversal)
	if self.Mode == "Slide" then
		VFX.slide(self.Model, false)
	elseif self.Mode == "WallRun" then
		VFX.wallRun(self.Model, nil)
	end
	self.Mode = nil
	self.BoostRemaining = 0
	self.Velocity.Enabled = false
	self.Orientation.Enabled = false
	self.Effects:action(nil)
	if self.WallSound then
		self.WallSound:Destroy()
		self.WallSound = nil
	end
end

function Traversal.slide(self: Traversal)
	self:stop()
	self.Mode = "Slide"
	self.Elapsed = 0
	self.Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	self.Velocity.PrimaryTangentAxis = Vector3.xAxis
	self.Velocity.SecondaryTangentAxis = Vector3.zAxis
	self.Orientation.CFrame = self.Root.CFrame.Rotation
	self.Orientation.Enabled = true
	self.Effects:action("Slide")
	Effects.sound(self.Root, "Slide")
	VFX.slide(self.Model, true)
end

function Traversal.wallRun(self: Traversal, side: string): boolean
	local hit = Traversal.wall(self.Root, self.Params, side)
	if not hit then
		return false
	end
	self:stop()
	self.Mode = "WallRun"
	self.Side = side
	self.Elapsed = 0
	self.WallNormal = hit.Normal
	self.WallPosition = hit.Position
	self.WallTangent = alongWall(self.Root, hit.Normal)
	self.Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	self.Velocity.VectorVelocity = self.WallTangent * Config.WallRun.Speed
	self.Velocity.Enabled = true
	self.Orientation.CFrame = CFrame.lookAt(Vector3.zero, self.WallTangent)
	self.Orientation.Enabled = true
	self.Effects:action(side .. "Wall")
	self.WallSound = Effects.sound(self.Root, "WallRun")
	VFX.wallRun(self.Model, side)
	return true
end

function Traversal.jump(self: Traversal, kind: string, scale: number)
	local normal = self.WallNormal
	local wallFrame = if kind == "Left" or kind == "Right"
		then CFrame.lookAt(self.WallPosition, self.WallPosition + normal) else nil
	VFX.jump(kind, self.Root.CFrame, self.Params, wallFrame)
	self:stop()
	local velocity = self.Root.AssemblyLinearVelocity * Horizontal
	local lift = if kind == "Double" then Config.Jump.DoublePower else Config.Jump.Power
	local sound = if kind == "Double" then "DoubleJump" else "Jump"
	if kind == "Slide" then
		velocity = self.Root.CFrame.LookVector * Horizontal * Config.Slide.BoostSpeed * scale
		lift = Config.Slide.BoostLift
		self.BoostRemaining = Config.Slide.BoostDuration
		self.Effects:variant("Boost", 8)
		sound = "SlideJump"
	elseif kind == "Left" or kind == "Right" then
		velocity = ((self.WallTangent + normal) * Horizontal).Unit * Config.WallRun.JumpSpeed * scale
		lift = Config.WallRun.JumpLift
		self.BoostRemaining = Config.WallRun.JumpDuration
		self.Effects:action(if kind == "Right" then "Boost4" else "Boost7")
		sound = "WallJump"
	elseif kind == "Double" then
		self.Effects:variant("DoubleJump", 4)
	else
		self.Effects:action("Jump")
	end
	velocity += Vector3.yAxis * lift
	self.Root.AssemblyLinearVelocity = velocity
	if self.BoostRemaining > 0 then
		self.Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		self.Velocity.VectorVelocity = velocity
		self.Velocity.Enabled = true
	end
	Effects.sound(self.Root, sound)
end

function Traversal.dash(self: Traversal, direction: Vector3)
	self:stop()
	self.BoostRemaining = Config.Dash.Duration
	local velocity = direction * Config.Dash.Speed
	self.Root.AssemblyLinearVelocity = velocity
	self.Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	self.Velocity.VectorVelocity = velocity
	self.Velocity.Enabled = true
	self.Effects:action("Boost2")
end

function Traversal.update(self: Traversal, delta: number, direction: Vector3, scale: number): boolean
	if self.BoostRemaining > 0 then
		self.BoostRemaining = math.max(0, self.BoostRemaining - delta)
		local velocity = self.Velocity.VectorVelocity
		local hit = workspace:Raycast(self.Root.Position,
			velocity.Unit * (self.Root.Size.Magnitude * 0.5 + velocity.Magnitude * delta), self.Params)
		if hit and velocity:Dot(hit.Normal) < 0 then
			self.BoostRemaining = 0
			local current = self.Root.AssemblyLinearVelocity
			self.Root.AssemblyLinearVelocity = current - hit.Normal * math.min(current:Dot(hit.Normal), 0)
		end
		self.Velocity.Enabled = self.BoostRemaining > 0
	end
	if not self.Mode then
		return true
	end
	self.Elapsed += delta
	local root = self.Root
	if self.Mode == "Slide" then
		if self.Elapsed >= Config.Slide.Duration then
			return false
		end
		local forward = root.CFrame.LookVector * Horizontal
		if direction.Magnitude > 0.1 then
			forward = forward:Lerp(direction, 1 - math.exp(-10 * delta))
		end
		if forward.Magnitude < 0.001 then
			return false
		end
		forward = forward.Unit
		local speed = Config.Slide.Speed * scale * (1 - self.Elapsed / Config.Slide.Duration)
		local obstacle = workspace:Raycast(root.Position,
			forward * (root.Size.Magnitude * 0.5 + speed * delta), self.Params)
		if obstacle and math.abs(obstacle.Normal.Y) <= Config.WallRun.MaxNormalY then
			return false
		end
		self.Velocity.PlaneVelocity = Vector2.new(forward.X, forward.Z) * speed
		self.Velocity.Enabled = Traversal.floor(root, self.Params, Config.Jump.GroundDistance) ~= nil
		self.Orientation.CFrame = CFrame.lookAt(Vector3.zero, forward)
		return true
	end

	local hit = Traversal.wall(root, self.Params, self.Side)
	local floor = Traversal.floor(root, self.Params, Config.WallRun.GroundDistance)
	local obstruction = workspace:Raycast(root.Position, root.CFrame.LookVector, self.Params)
	if not hit or floor or obstruction or self.Elapsed >= Config.WallRun.Duration then
		return false
	end
	local tangent = alongWall(root, hit.Normal)
	self.WallNormal = hit.Normal
	self.WallPosition = hit.Position
	self.WallTangent = tangent
	local correction = hit.Normal * (Config.WallRun.Offset - hit.Distance) * 15
	self.Velocity.VectorVelocity = tangent * Config.WallRun.Speed * scale + correction
		- Vector3.yAxis * self.Elapsed * Config.WallRun.FallAcceleration
	self.Orientation.CFrame = CFrame.lookAt(Vector3.zero, tangent)
	return true
end

function Traversal.destroy(self: Traversal)
	self:stop()
	self.Velocity:Destroy()
	self.Orientation:Destroy()
	self.Attachment:Destroy()
end

export type Traversal = typeof(Traversal) & {
	Root: BasePart, Model: Model, Params: RaycastParams, Effects: Effects.Effects,
	Attachment: Attachment, Velocity: LinearVelocity, Orientation: AlignOrientation,
	Mode: string?, Elapsed: number, BoostRemaining: number,
	Side: string, WallNormal: Vector3, WallTangent: Vector3, WallPosition: Vector3, WallSound: Sound?,
}

return Traversal
