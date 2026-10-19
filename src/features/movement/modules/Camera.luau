local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CameraController = require(ReplicatedStorage.Source.Game.Modules.Camera.CameraController)
local OrbitCamera = require(ReplicatedStorage.Source.Game.Modules.Camera.OrbitCamera)
local Config = require(ReplicatedStorage.Source.Features.Movement.Config).Camera

local Camera = {}
Camera.__index = Camera

function Camera.new(root: BasePart, params: RaycastParams)
	return setmetatable({
		Root = root, Torso = root.Parent.Torso, Joint = root.RootJoint,
		OriginalC0 = root.RootJoint.C0, TorsoOffset = Vector3.zero, ReturnElapsed = 0,
		Controller = CameraController.new(workspace.CurrentCamera, Config.FieldOfView),
		Orbit = OrbitCamera.new(Config, params),
	}, Camera)
end

function Camera.boost(self: Camera, name: string)
	local boost = Config.Boosts[name]
	self.Controller:pulse("Movement" .. name, boost.Amount, boost.Duration)
	if name == "SlideJump" then
		if self.Blur then
			self.Blur:Destroy()
		end
		local blur = Instance.new("DepthOfFieldEffect")
		blur.FocusDistance = Config.Blur.FocusDistance
		blur.FarIntensity = Config.Blur.Intensity
		blur.NearIntensity = 0
		blur.InFocusRadius = Config.Blur.InFocusRadius
		blur.Parent = self.Controller.Instance
		self.Blur = blur
		local tween = TweenService:Create(blur, TweenInfo.new(Config.Blur.Duration), { FarIntensity = 0 })
		tween.Completed:Once(function()
			blur:Destroy()
			if self.Blur == blur then
				self.Blur = nil
			end
		end)
		tween:Play()
	end
end

function Camera.face(self: Camera, delta: number, direction: Vector3, mode: string?)
	if mode or not self.Controller.Enabled then
		return
	end
	local root = self.Root
	if self.Orbit.ShiftLocked then
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, self.Orbit.Yaw, 0)
	elseif direction.Magnitude > 0.1 then
		local distance = (direction - root.CFrame.LookVector).Magnitude
		local alpha = if distance > 0.001 then math.min(Config.TurnSpeed * delta / distance, 1) else 1
		root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, root.Position + direction), alpha)
	end
end

function Camera.update(self: Camera, delta: number, grounded: boolean, mode: string?)
	self.Orbit:setEnabled(self.Controller.Enabled)
	if not self.Controller.Enabled then
		self.Joint.C0 = self.OriginalC0
		return
	end
	local alpha = 1 - math.exp(-Config.Smoothing * delta)
	local offset = self.Root.CFrame:PointToObjectSpace(self.Torso.Position) * Config.TorsoScale
	self.TorsoOffset = self.TorsoOffset:Lerp(offset, alpha)
	local focus = self.Root.Position + self.TorsoOffset
	local frame = self.Orbit:update(delta, focus, self.Root.Position)
	if not grounded and not mode then
		self.Joint.C0 = self.OriginalC0 * CFrame.Angles(-self.Orbit.Pitch, 0, 0)
		self.ReturnElapsed = 0
	else
		self.ReturnElapsed += delta
		self.Joint.C0 = self.Joint.C0:Lerp(self.OriginalC0, math.min(self.ReturnElapsed / Config.BodyReturnDuration, 1))
	end
	self.Controller:render(frame, focus, delta)
end

function Camera.destroy(self: Camera)
	self.Joint.C0 = self.OriginalC0
	if self.Blur then
		self.Blur:Destroy()
	end
	self.Orbit:destroy()
	self.Controller:destroy()
end

export type Camera = typeof(Camera) & {
	Root: BasePart, Torso: BasePart, Joint: Motor6D, OriginalC0: CFrame,
	TorsoOffset: Vector3, ReturnElapsed: number, Blur: DepthOfFieldEffect?,
	Controller: CameraController.CameraController, Orbit: OrbitCamera.OrbitCamera,
}

return Camera
