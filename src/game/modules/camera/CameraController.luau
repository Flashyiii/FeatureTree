local CameraController = {}
CameraController.__index = CameraController
type RobloxCamera = Camera

function CameraController.new(camera: RobloxCamera, fieldOfView: number)
	local self = setmetatable({
		Instance = camera, FieldOfView = fieldOfView, Modifiers = {}, Enabled = true,
		OriginalType = camera.CameraType, OriginalSubject = camera.CameraSubject, OriginalFov = camera.FieldOfView,
	}, CameraController)
	camera.CameraType = Enum.CameraType.Scriptable
	return self
end

function CameraController.setModifier(self: CameraController, name: string, value: number)
	self.Modifiers[name] = { Value = value, Elapsed = 0 }
end

function CameraController.pulse(self: CameraController, name: string, value: number, duration: number)
	self.Modifiers[name] = { Value = value, Duration = duration, Elapsed = 0 }
end

function CameraController.removeModifier(self: CameraController, name: string)
	self.Modifiers[name] = nil
end

function CameraController.render(self: CameraController, frame: CFrame, focus: Vector3, delta: number)
	if not self.Enabled then
		return
	end
	local fieldOfView = self.FieldOfView
	for name, modifier in self.Modifiers do
		if modifier.Duration then
			modifier.Elapsed = math.min(modifier.Elapsed + delta, modifier.Duration)
			local alpha = modifier.Elapsed / modifier.Duration
			fieldOfView += modifier.Value * (1 - alpha) ^ 2
			if alpha == 1 then
				self.Modifiers[name] = nil
			end
		else
			fieldOfView += modifier.Value
		end
	end
	self.Instance.CFrame = frame
	self.Instance.Focus = CFrame.new(focus)
	self.Instance.FieldOfView = fieldOfView
end

function CameraController.destroy(self: CameraController)
	self.Instance.CameraType = self.OriginalType
	self.Instance.CameraSubject = self.OriginalSubject
	self.Instance.FieldOfView = self.OriginalFov
end

export type CameraController = typeof(CameraController) & {
	Instance: RobloxCamera, FieldOfView: number, Enabled: boolean,
	OriginalType: Enum.CameraType, OriginalSubject: Instance?, OriginalFov: number,
	Modifiers: { [string]: { Value: number, Duration: number?, Elapsed: number } },
}

return CameraController
