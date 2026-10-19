local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Source.Features.Movement.Config)
local Effects = require(ReplicatedStorage.Source.Features.Movement.Modules.Effects)
local Assets = ReplicatedStorage.Assets.VFX.Movement

local VFX = {}
local SlideStarts = {} :: { [Model]: thread }
local BurstRotations = {
	["walljump main"] = CFrame.Angles(0, math.rad(90), 0),
	["walljump specholder"] = CFrame.Angles(math.rad(-90), math.rad(-180), 0),
	["walljump wall"] = CFrame.Angles(0, math.rad(90), math.rad(90)),
	["slidejump floor"] = CFrame.identity,
	["slidejump mainflash"] = CFrame.Angles(0, math.rad(90), math.rad(45.401)),
	["slidejump specholder"] = CFrame.Angles(0, math.rad(90), 0),
}

local function clone(template: BasePart): BasePart
	local part = template:Clone()
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	return part
end

local function attach(template: BasePart, target: BasePart, name: string, offset: CFrame)
	local part = clone(template)
	part.Name = name
	part.Anchored = false
	part.CFrame = target.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = target
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = target
end

function VFX.slide(model: Model, started: boolean)
	if SlideStarts[model] then
		task.cancel(SlideStarts[model])
		SlideStarts[model] = nil
	end
	if not model.Parent then
		return
	end
	local hilt = model.RightMovementHilt
	local effect = hilt:FindFirstChild("MovementSlide")
	if effect then
		effect.Trail.Enabled = false
		effect.Sparks.Enabled = false
	end
	local sound = hilt:FindFirstChild("MovementSlideSparkle")
	if sound then
		sound:Destroy()
	end
	if not started then
		return
	end

	SlideStarts[model] = task.delay(Config.VFX.SlideDelay, function()
		SlideStarts[model] = nil
		if not model.Parent then
			return
		end
		if not effect then
			effect = Assets.Slide.Effect:Clone()
			effect.Name = "MovementSlide"
			for endpoint, offset in Config.VFX.SlideTrailOffsets do
				local attachment = Instance.new("Attachment")
				attachment.Position = offset
				attachment.Parent = hilt
				effect.Trail[endpoint] = attachment
			end
			effect.Parent = hilt
		end
		effect.Trail.Enabled = true
		effect.Sparks.Enabled = true
		Effects.sound(hilt, "SlideSparkle")
	end)
end

function VFX.wallRun(model: Model, side: string?)
	for _, name in { "MovementWallBackflash", "MovementWallHand" } do
		local effect = model:FindFirstChild(name, true)
		if effect then
			effect:Destroy()
		end
	end
	if not side then
		return
	end
	local root = model.HumanoidRootPart
	local angle = if side == "Left" then 135 else -135
	attach(
		Assets.WallRun.backflash,
		root,
		"MovementWallBackflash",
		CFrame.Angles(math.rad(-90), math.rad(angle), math.rad(90))
	)
	local arm = model[side .. " Arm"]
	attach(Assets.WallRun[Config.VFX.HandTemplates[side]], arm, "MovementWallHand", Config.VFX.HandOffset)
end

function VFX.jump(kind: string, origin: CFrame, params: RaycastParams, wallFrame: CFrame?)
	local folder
	local frame
	if kind == "Slide" then
		local hit = workspace:Raycast(origin.Position, -Vector3.yAxis * Config.Slide.GroundDistance, params)
		if not hit then
			return
		end
		folder = Assets.JumpEffects.SlideJumpVfx
		frame = CFrame.lookAt(hit.Position, hit.Position + origin.LookVector)
	elseif kind == "Left" or kind == "Right" then
		if not wallFrame then
			local sign = if kind == "Left" then -1 else 1
			local hit = workspace:Raycast(origin.Position, origin.RightVector * sign * Config.WallRun.Distance, params)
			if not hit then
				return
			end
			wallFrame = CFrame.lookAt(hit.Position, hit.Position + hit.Normal)
		end
		folder = Assets.JumpEffects.WallJumpVfx
		frame = wallFrame
	else
		return
	end
	for _, template in folder:GetChildren() do
		local part = clone(template)
		part.Anchored = true
		part.Transparency = 1
		part.CFrame = frame * BurstRotations[part.Name]
		part.Parent = workspace
		for _, emitter in part:GetDescendants() do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = false
				emitter:Emit(emitter:GetAttribute("EmitCount") or Config.VFX.EmitCount)
			end
		end
		Debris:AddItem(part, Config.VFX.Lifetime)
	end
end

return VFX
