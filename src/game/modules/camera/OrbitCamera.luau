local UserInputService = game:GetService("UserInputService")

local OrbitCamera = {}
OrbitCamera.__index = OrbitCamera

export type Settings = {
	Zoom: number, MinZoom: number, MaxZoom: number, ZoomStep: number,
	Sensitivity: number, SettingsSensitivity: number, GamepadSensitivity: number,
	PitchLimit: number, Smoothing: number, CollisionPadding: number,
	FreeOffset: Vector3, LockedOffset: Vector3,
}

function OrbitCamera.new(settings: Settings, params: RaycastParams)
	local self = setmetatable({
		Settings = settings, Params = params, Yaw = 0, Pitch = 0, ShiftLocked = false,
		Zoom = settings.Zoom, CurrentZoom = settings.Zoom, Offset = Vector3.zero,
		Stick = Vector2.zero, Enabled = true, Focused = true,
		OriginalMouse = UserInputService.MouseBehavior,
		UserGameSettings = UserSettings():GetService("UserGameSettings"),
	}, OrbitCamera)
	self.InputConnection = UserInputService.InputChanged:Connect(function(input, processed)
		if processed or not self.Enabled then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			self.Zoom = math.clamp(self.Zoom - input.Position.Z * settings.ZoomStep, settings.MinZoom, settings.MaxZoom)
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local stick = Vector2.new(input.Position.X, input.Position.Y)
			self.Stick = if stick.Magnitude > 0.15 then stick else Vector2.zero
		end
	end)
	self.FocusLostConnection = UserInputService.WindowFocusReleased:Connect(function()
		self.Focused = false
		self.Stick = Vector2.zero
		if self.Enabled then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)
	self.FocusGainedConnection = UserInputService.WindowFocused:Connect(function()
		self.Focused = true
	end)
	return self
end

function OrbitCamera.setEnabled(self: OrbitCamera, enabled: boolean)
	if self.Enabled == enabled then
		return
	end
	self.Enabled = enabled
	if not enabled then
		self.Stick = Vector2.zero
		UserInputService.MouseBehavior = self.OriginalMouse
	end
end

function OrbitCamera.update(self: OrbitCamera, delta: number, focus: Vector3, collisionOrigin: Vector3): CFrame
	local settings = self.Settings
	local rotating = self.ShiftLocked or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	local input = Vector2.zero
	if not self.Focused or UserInputService:GetFocusedTextBox() then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	else
		if rotating then
			UserInputService.MouseBehavior = if self.ShiftLocked then Enum.MouseBehavior.LockCenter
				else Enum.MouseBehavior.LockCurrentPosition
			local sensitivity = settings.Sensitivity + self.UserGameSettings.MouseSensitivity * settings.SettingsSensitivity
			input = UserInputService:GetMouseDelta() * sensitivity
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		input += Vector2.new(self.Stick.X, -self.Stick.Y) * delta * settings.GamepadSensitivity
	end
	self.Yaw -= input.X
	self.Pitch = math.clamp(self.Pitch - input.Y, -settings.PitchLimit, settings.PitchLimit)
	local alpha = 1 - math.exp(-settings.Smoothing * delta)
	self.CurrentZoom += (self.Zoom - self.CurrentZoom) * alpha
	self.Offset = self.Offset:Lerp(if self.ShiftLocked then settings.LockedOffset else settings.FreeOffset, alpha)
	local rotation = CFrame.Angles(0, self.Yaw, 0) * CFrame.Angles(self.Pitch, 0, 0)
	local target = CFrame.new(focus) * rotation * CFrame.new(self.Offset + Vector3.zAxis * self.CurrentZoom)
	local displacement = target.Position - collisionOrigin
	if displacement.Magnitude > 0.001 then
		local hit = workspace:Raycast(collisionOrigin, displacement, self.Params)
		if hit then
			target = CFrame.new(hit.Position + hit.Normal * settings.CollisionPadding) * rotation
		end
	end
	return target
end

function OrbitCamera.destroy(self: OrbitCamera)
	self.InputConnection:Disconnect()
	self.FocusLostConnection:Disconnect()
	self.FocusGainedConnection:Disconnect()
	UserInputService.MouseBehavior = self.OriginalMouse
end

export type OrbitCamera = typeof(OrbitCamera) & {
	Settings: Settings, Params: RaycastParams, Yaw: number, Pitch: number, ShiftLocked: boolean,
	Zoom: number, CurrentZoom: number, Offset: Vector3, Stick: Vector2, Enabled: boolean, Focused: boolean,
	OriginalMouse: Enum.MouseBehavior, InputConnection: RBXScriptConnection,
	FocusLostConnection: RBXScriptConnection, FocusGainedConnection: RBXScriptConnection,
	UserGameSettings: UserGameSettings,
}

return OrbitCamera
