local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationIds = require(ReplicatedStorage.Source.Game.Assets.AnimationIds).Movement
local SoundIds = require(ReplicatedStorage.Source.Game.Assets.SoundIds).Movement
local Config = require(ReplicatedStorage.Source.Features.Movement.Config)

local Effects = {}
Effects.__index = Effects

local Looped = { Idle = true, Run = true, FallNormal = true, FallFlail = true, Slide = true, LeftWall = true, RightWall = true }
local Locomotion = { Idle = true, Run = true, FallNormal = true, FallFlail = true }

function Effects.new(root: BasePart, animator: Animator)
	local self = setmetatable({ Root = root, Tracks = {}, Action = nil, LastVariant = {} }, Effects)
	for name, id in AnimationIds do
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local track = animator:LoadAnimation(animation)
		animation:Destroy()
		track.Looped = Looped[name] == true
		track.Priority = if name == "Idle" then Enum.AnimationPriority.Idle
			elseif Locomotion[name] then Enum.AnimationPriority.Movement
			else Enum.AnimationPriority.Action
		self.Tracks[name] = track
	end
	return self
end

function Effects.sound(root: BasePart, name: string): Sound
	local data = SoundIds[name]
	local sound = Instance.new("Sound")
	sound.Name = "Movement" .. name
	sound.SoundId = data.Id
	sound.Volume = data.Volume
	sound.Looped = data.Looped == true
	sound.RollOffMaxDistance = 100
	sound.Parent = root
	sound:Play()
	if not sound.Looped then
		Debris:AddItem(sound, 5)
	end
	return sound
end

function Effects.play(self: Effects, name: string)
	local track = self.Tracks[name]
	if not track.IsPlaying then
		track:Play(0.1)
	end
end

function Effects.action(self: Effects, name: string?)
	if self.Action then
		self.Tracks[self.Action]:Stop(0.1)
	end
	self.Action = name
	if name then
		self:play(name)
	end
end

function Effects.variant(self: Effects, prefix: string, count: number)
	local previous = self.LastVariant[prefix]
	local index = math.random(1, if previous then count - 1 else count)
	if previous and index >= previous then
		index += 1
	end
	self.LastVariant[prefix] = index
	self:action(prefix .. index)
end

function Effects.update(self: Effects, grounded: boolean, moving: boolean, speed: number)
	local name = if not grounded then "FallNormal" elseif moving then "Run" else "Idle"
	for _, other in { "Idle", "Run", "FallNormal" } do
		if other == name then
			self:play(other)
		else
			self.Tracks[other]:Stop(0.1)
		end
	end
	self.Tracks.Run:AdjustSpeed(speed / Config.WalkSpeed)
	if not grounded and speed > 10 then
		self:play("FallFlail")
		self.Tracks.FallFlail:AdjustWeight(math.clamp(speed / 100, 0, 1))
	else
		self.Tracks.FallFlail:Stop(0.1)
	end
end

function Effects.land(self: Effects, speed: number)
	if speed > 25 then
		self:action(if speed < 125 then "Land" else "Roll")
		Effects.sound(self.Root, if speed < 125 then "LightLand" else "HeavyLand")
	end
end

function Effects.destroy(self: Effects)
	for _, track in self.Tracks do
		track:Stop(0)
		track:Destroy()
	end
end

export type Effects = typeof(Effects) & {
	Root: BasePart, Tracks: { [string]: AnimationTrack },
	Action: string?, LastVariant: { [string]: number },
}

return Effects
