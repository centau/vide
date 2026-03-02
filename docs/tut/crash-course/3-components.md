# Components

Vide encourages separating different parts of your UI into functions called
*components*.

A component is a function that creates and returns a piece of UI.

This is a way to separate your UI into small chunks that you can reuse and put
together.

::: code-group

```luau [Button.luau]
local create = vide.create

local function Button(props: {
	Position: UDim2,
	Text: string,
	Activated: () -> ()
})
	return create "TextButton" {
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromOffset(200, 150),

		Position = props.Position,
		Text = props.Text,
		Activated = props.Activated,

		create "UICorner" {}
	}
end

return Button

local create = vide.create
local source = vide.source
local effect = vide.effect

local Button = require(Button)
local Slider = require(Slider)

local fov = source(70)

effect(function()
	local cam = workspace.CurrentCamera
	if cam then
		cam.FieldOfView = fov()
	end
end)

local function Menu()
	return create "ScreenGui" {
		Button {
			Position = UDim2.fromOffset(200, 200),
			Text = "back",
			Activated = function()
				print "go to previous page"
			end
		},

		Button {
			Position = UDim2.fromOffset(400, 200),
			Text = "next",
			Activated = function()
				print "go to next page"
			end
		},

		-- Settings menu panel (example usage of Slider component)
		create "Frame" {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromOffset(24, 560),
			Size = UDim2.fromOffset(560, 220),
			BackgroundTransparency = 0.1,

			create "UICorner" { CornerRadius = UDim.new(0, 16) },
			create "UIPadding" {
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			},

			create "UIListLayout" {
				Padding = UDim.new(0, 14),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			create "TextLabel" {
				LayoutOrder = 0,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(528, 28),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 20,
				Text = "Settings",
			},

			Slider {
				layoutOrder = 1,
				label = "Camera FOV",
				min = 60,
				max = 90,
				step = 1,
				value = fov,
				format = function(v)
					return string.format("%d", math.floor(v + 0.5))
				end,
			},
		},
	}
end

return Menu
-- Example of a component that wraps the built-in slider component.
-- This keeps a consistent "component(props) -> Instance" style.

local source = vide.source

export type SliderTheme = {
	trackColor: Color3?,
	trackTransparency: number?,
	fillColor: Color3?,
	fillTransparency: number?,
	knobColor: Color3?,
	knobTransparency: number?,
	strokeColor: Color3?,
	strokeTransparency: number?,
	cornerRadius: number?,
	knobRadius: number?,
}

export type SliderProps = {
	-- required
	value: source.source<number>,

	-- range
	min: number?,
	max: number?,
	step: number?,

	-- text
	label: string?,
	format: ((number) -> string)?,
	onChanged: ((number) -> ())?,

	-- layout
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,

	-- style
	theme: SliderTheme?,
}

local function Slider(props: SliderProps)
	return vide.slider(props)
end

return Slider
```
:::
