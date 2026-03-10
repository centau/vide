local create = require "./create"
local source = require "./source"

return function(props)
	props = props or {}

	local state = props.value
	if state == nil then
		state = source(props.default == true)
	end

	if type(state) ~= "function" then
		error("vide.toggle: props.value must be a Source<boolean> (callable), or omitted for internal state", 2)
	end

	local theme = props.theme or {}
  
	local onColor = theme.onColor
	local offColor = theme.offColor
	local knobColor = theme.knobColor
	local knobTransparency = theme.knobTransparency

	local strokeColor = theme.strokeColor
	local strokeTransparency = theme.strokeTransparency

	local labelColor = theme.labelColor
	local subLabelColor = theme.subLabelColor

	local trackW = props.trackWidth or 56
	local trackH = props.trackHeight or 28
	local knob = props.knobSize or 22
	local pad = props.knobPadding or 3
	local radius = theme.cornerRadius or 999

	local bind = props.bind
	if bind then
		bind(state())
	end

	local function emit(nextValue)
		if props.onChanged then
			props.onChanged(nextValue)
		end
		if bind then
			bind(nextValue)
		end
	end

	local function set(nextValue)
		state(nextValue)
		emit(nextValue)
	end

	local function toggle()
		set(not state())
	end

	local function corner(px)
		return create "UICorner" { CornerRadius = UDim.new(0, px or radius) }
	end

	local function stroke()
		if strokeColor == nil and strokeTransparency == nil then
			return nil
		end
		return create "UIStroke" {
			Color = strokeColor,
			Transparency = strokeTransparency,
			Thickness = 1,
		}
	end

local function trackBackground()
		if onColor ~= nil and offColor ~= nil then
			return function()
				return state() and onColor or offColor
			end
		end
		return nil
	end

	return create "Frame" {
		Name = props.name or "Toggle",
		Size = props.size or UDim2.fromOffset(360, trackH),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,

		-- Label area (left)
		create "Frame" {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -(trackW + 12), 1, 0),

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			},

			create "TextLabel" {
				LayoutOrder = 0,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 18),
				Text = props.label or "Toggle",
				TextColor3 = labelColor,
				TextSize = props.labelTextSize or 16,
				Font = props.font or Enum.Font.Gotham,
			},

			create "TextLabel" {
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 16),
				Text = props.description or "",
				TextColor3 = subLabelColor,
				TextSize = props.descriptionTextSize or 13,
				Font = props.font or Enum.Font.Gotham,
			},
		},

		
		create "TextButton" {
			Name = "Switch",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(trackW, trackH),
			Text = "",
			AutoButtonColor = not props.disabled,
			Active = not props.disabled,
			Selectable = true,
      
			BackgroundColor3 = trackBackground(),

			Activated = function()
				if props.disabled then return end
				toggle()
			end,

			corner(),
			stroke(),

			create "Frame" {
				Name = "Knob",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = function()
					local x = state() and (trackW - pad - knob) or pad
					return UDim2.fromOffset(x, trackH / 2)
				end,
				Size = UDim2.fromOffset(knob, knob),
				BackgroundColor3 = knobColor,
				BackgroundTransparency = knobTransparency,
				corner(),
			},
		},
	}
end
