local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)
local useViewportSize = require(ReplicatedStorage.Source.UI.Hooks.useViewportSize)

local create = Vide.create
local derive = Vide.derive

local STUDIO_SIZE = Vector2.new(1500, 803)

export type AutoScaledFrameProps = {
	ScaleFactor: number?,
	MinSize: Vector2?,
	Size: UDim2,
	Position: UDim2?,
	Rotation: number?,
	AnchorPoint: Vector2?,
	BackgroundTransparency: number?,
	ZIndex: number?,
	Children: any?,
}

return function(props: AutoScaledFrameProps)
	local screenSize = useViewportSize()
	local minSize = props.MinSize or Vector2.zero
	local scaleFactor = props.ScaleFactor or 1
	
	local minScale = derive(function()
		local sizeX = props.Size.X.Offset
		local sizeY = props.Size.Y.Offset
		
		local scaleX = if sizeX > 0 then minSize.X / sizeX else 0
		local scaleY = if sizeY > 0 then minSize.Y / sizeY else 0
		
		return math.max(scaleX, scaleY)
	end)

	local scale = derive(function()
		local s = screenSize()
		local newScale = scaleFactor * math.min(s.X / STUDIO_SIZE.X, s.Y / STUDIO_SIZE.Y)
		return math.max(newScale, minScale())
	end)

	return create "Frame" {
		Name = "AutoScaledFrame",
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Rotation = props.Rotation,
		ZIndex = props.ZIndex,
		BackgroundTransparency = props.BackgroundTransparency or 1,

		create "UIScale" {
			Scale = scale,
		},

		props.Children,
	}
end
