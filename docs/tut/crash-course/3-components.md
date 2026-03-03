# Components

Vide encourages separating different parts of your UI into functions called
*components*.

A component is a function that creates and returns a piece of UI.

This is a way to separate your UI into small chunks that you can reuse and put
together.

::: code-group

```lua [Button.luau]
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
```
```luau [toggle.luau]
local toggle = vide.toggle
local source = vide.source

local enabled = source(true)

return function()
	return toggle {
		label = "Music",
		description = "Enable background music",
		value = enabled, -- Source<boolean>
		onChanged = function(v)
			print("Music:", v)
		end,
		-- optional theme (omit if you want defaults / neutral)
		theme = {
			onColor = Color3.fromRGB(80, 140, 255),
			offColor = Color3.fromRGB(18, 20, 26),
			knobColor = Color3.fromRGB(245, 247, 252),
			strokeColor = Color3.fromRGB(255, 255, 255),
			strokeTransparency = 0.88,
			labelColor = Color3.fromRGB(245, 247, 252),
			subLabelColor = Color3.fromRGB(190, 196, 210),
			cornerRadius = 999,
		},
	}
end
```

```luau [dropdown.luau]
local dropdown = vide.dropdown
local source = vide.source

local selected = source("All")
local isOpen = source(false)

local options = {
	"All",
	"Public",
	"Private",
	"Friends",
	"Full",
	"Empty",
	"Region: EU",
	"Region: NA",
}

return function()
	return dropdown {
		size = UDim2.fromOffset(260, 44),

		-- state
		value = selected,   -- Source<string>
		open = isOpen,      -- Source<boolean>

		-- options
		options = options,
		placeholder = "Select…",
		closeOnSelect = true,

		-- scrolling
		maxVisible = 4,
		rowHeight = 36,
		gap = 8,
		scrollBarThickness = 6,

		-- layering (recommended if you have other UI nearby)
		baseZIndex = 200,

		onChanged = function(v)
			print("Selected:", v)
		end,

		-- optional theme
		theme = {
			boxBg = Color3.fromRGB(18, 20, 26),
			boxBgTransparency = 0,
			boxStroke = Color3.fromRGB(255, 255, 255),
			boxStrokeTransparency = 0.88,

			listBg = Color3.fromRGB(12, 13, 16),
			listBgTransparency = 0,
			listStroke = Color3.fromRGB(255, 255, 255),
			listStrokeTransparency = 0.88,

			textColor = Color3.fromRGB(245, 247, 252),
			itemBg = Color3.fromRGB(18, 20, 26),
			itemBgTransparency = 0,

			cornerRadius = 12,
			itemCornerRadius = 10,
		},
	}
end
```

```luau [slider.luau]
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
	value: source.source<number>,

	min: number?,
	max: number?,
	step: number?,

	label: string?,
	format: ((number) -> string)?,
	onChanged: ((number) -> ())?,

	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,

	theme: SliderTheme?,
}

local function Slider(props: SliderProps)
	return vide.slider(props)
end

return Slider
```

```luau [menu.luau]
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
```

:::
