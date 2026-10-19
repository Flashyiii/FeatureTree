local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Networker = require(ReplicatedStorage.Packages.Networker)
local WCS = require(ReplicatedStorage.Packages.wcs)
local Config = require(ReplicatedStorage.Source.Features.Movement.Config)
local Character = require(ReplicatedStorage.Source.Features.Movement.Modules.Character)
local Effects = require(ReplicatedStorage.Source.Features.Movement.Modules.Effects)
local Traversal = require(ReplicatedStorage.Source.Features.Movement.Modules.Traversal)
local VFX = require(ReplicatedStorage.Source.Features.Movement.Modules.VFX)
require(ReplicatedStorage.Source.Features.Movement.Modules.Skills)

local MovementClient = {}

function MovementClient.init(self: MovementClient)
	self.Cleanup = Janitor.new()
	self.SlideInputs = {}
	self.Network = Networker.client.new("Movement", self)
	self.Handler = WCS.CreateClient()
	self.Cleanup:Add(WCS.Character.CharacterCreated:Connect(function(character)
		if character.Instance == Players.LocalPlayer.Character then
			self:addCharacter(character)
		end
	end))
	self.Handler:Start()
	local current = WCS.Character.GetLocalCharacter()
	if current then
		self:addCharacter(current)
	end
	self:bindInputs()
	self.Cleanup:Add(UserInputService.WindowFocusReleased:Connect(function()
		table.clear(self.SlideInputs)
		if self.Character then
			self.Character.HoldingSlide = false
			self.Character:endTraversal()
		end
	end))
	self.Cleanup:Add(RunService.PreSimulation:Connect(function(delta)
		if self.Character then
			self.Character:update(delta)
		end
	end))
	RunService:BindToRenderStep("Movement", Enum.RenderPriority.Camera.Value + 1, function(delta)
		if self.Character then
			local movement = self.Character
			movement.Camera:update(delta, movement.Grounded, movement.Traversal.Mode)
		end
	end)
end

function MovementClient.addCharacter(self: MovementClient, character: WCS.Character)
	if self.Character and self.Character.WCS == character then
		return
	end
	if self.Character then
		self.Character:destroy()
		self.Character = nil
	end
	table.clear(self.SlideInputs)
	local movement = Character.new(character)
	if character:IsDestroyed() or character.Instance ~= Players.LocalPlayer.Character then
		movement:destroy()
		return
	end
	self.Character = movement
	character.Destroyed:Once(function()
		movement:destroy()
		if self.Character == movement then
			self.Character = nil
		end
	end)
end

function MovementClient.bindInputs(self: MovementClient)
	for name, keys in Config.Inputs do
		ContextActionService:BindActionAtPriority("Movement" .. name, function(_, state, input)
			local movement = self.Character
			if not movement then
				return Enum.ContextActionResult.Pass
			end
			if name == "Slide" and state ~= Enum.UserInputState.Begin then
				self.SlideInputs[input.KeyCode] = nil
				movement.HoldingSlide = next(self.SlideInputs) ~= nil
				if not movement.HoldingSlide and movement.Traversal.Mode == "Slide" then
					movement:endTraversal()
				end
			elseif UserInputService:GetFocusedTextBox() then
				return Enum.ContextActionResult.Pass
			elseif name == "Jump" and state == Enum.UserInputState.Begin then
				local kind = movement:jumpKind()
				if kind then
					movement:request("Jump", kind)
				end
			elseif name == "Dash" and state == Enum.UserInputState.Begin then
				movement:request("Dash")
			elseif name == "Slide" and state == Enum.UserInputState.Begin then
				self.SlideInputs[input.KeyCode] = true
				movement.HoldingSlide = true
				movement:request("Slide")
			elseif name == "ShiftLock" and state == Enum.UserInputState.Begin then
				movement.Camera.Orbit.ShiftLocked = not movement.Camera.Orbit.ShiftLocked
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, table.unpack(keys))
	end
end

function MovementClient.effect(
	self: MovementClient, model: Model, skill: string, started: boolean, kind: string?, origin: CFrame?
)
	if not model or model == Players.LocalPlayer.Character then
		return
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if skill == "MovementJump" and started then
		local sound = if kind == "Double" then "DoubleJump" elseif kind == "Slide" then "SlideJump"
			elseif kind == "Left" or kind == "Right" then "WallJump" else "Jump"
		Effects.sound(root, sound)
		VFX.jump(kind :: string, origin :: CFrame, Traversal.params(model))
	elseif skill == "MovementSlide" then
		VFX.slide(model, started)
		if started then
			Effects.sound(root, "Slide")
		end
	elseif skill == "MovementWallRun" then
		VFX.wallRun(model, if started then kind else nil)
		local sound = root:FindFirstChild("MovementWallRun")
		if sound then
			sound:Destroy()
		end
		if started then
			Effects.sound(root, "WallRun")
		end
	end
end

function MovementClient.destroy(self: MovementClient)
	RunService:UnbindFromRenderStep("Movement")
	for name in Config.Inputs do
		ContextActionService:UnbindAction("Movement" .. name)
	end
	self.Cleanup:Destroy()
	self.Network:destroy()
	if self.Character then
		self.Character:destroy()
		self.Character = nil
	end
end

export type MovementClient = typeof(MovementClient) & {
	Cleanup: Janitor.Janitor, Network: Networker.Client, Handler: WCS.Client,
	Character: Character.Character?, SlideInputs: { [Enum.KeyCode]: boolean },
}

return MovementClient
