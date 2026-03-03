-- src/dropdown.luau
local create = require "./create"
local source = require "./source"

return function(props)
	props = props or {}

	local value = props.value
	if value == nil then
		value = source(props.default)
	end
	if type(value) ~= "function" then
		error("vide.dropdown: props.value must be a Source<T> (callable), or omitted for internal state", 2)
	end

	local open = props.open
	if open == nil then
		open = source(props.defaultOpen == true)
	end
	if type(open) ~= "function" then
		error("vide.dropdown: props.open must be a Source<boolean> (callable), or omitted for internal state", 2)
	end

	local options = props.options or {}
	local closeOnSelect = (props.closeOnSelect ~= false)

	-- Sizing
	local width = props.width or 160
	local height = props.height or 44
	local rowHeight = props.rowHeight or 36
	local gap = props.gap or 8
	local maxVisible = props.maxVisible or 4

	-- Theme (neutral only applied if provided)
	local theme = props.theme or {}

	local boxBg = theme.boxBg
	local boxBgT = theme.boxBgTransparency
	local boxStroke = theme.boxStroke
	local boxStrokeT = theme.boxStrokeTransparency

	local listBg = theme.listBg
	local listBgT = theme.listBgTransparency
	local listStroke = theme.listStroke
	local listStrokeT = theme.listStrokeTransparency

	local textColor = theme.textColor
	local itemBg = theme.itemBg
	local itemBgT = theme.itemBgTransparency

	local radius = theme.cornerRadius or 12
	local itemRadius = theme.itemCornerRadius or 10

	-- Helpers
	local function Corner(px)
		return create "UICorner" { CornerRadius = UDim.new(0, px) }
	end

	local function Stroke(color, transparency)
		if color == nil and transparency == nil then
			return nil
		end
		return create "UIStroke" {
			Color = color,
			Transparency = transparency,
			Thickness = 1,
		}
	end

	local function set(v)
		value(v)
		if props.onChanged then
			props.onChanged(v)
		end
	end

	local function toggleOpen()
		open(not open())
		if open() and props.onOpen then props.onOpen() end
		if (not open()) and props.onClose then props.onClose() end
	end

	-- Option model:
	-- - string/number/etc: label = tostring(opt), value = opt
	-- - table: { label = "All", value = "All", disabled = true }
	local function normalize(opt)
		if type(opt) == "table" then
			return opt.label, opt.value, opt.disabled == true
		end
		return tostring(opt), opt, false
	end

	local function currentLabel()
		local v = value()
		if v == nil then
			return props.placeholder or ""
		end
		-- options have tables match value thing
		for _, opt in ipairs(options) do
			local label, optValue = normalize(opt)
			if optValue == v then
				return label
			end
		end
		return tostring(v)
	end

	return create "Frame" {
		Name = props.name or "Dropdown",
		Size = props.size or UDim2.fromOffset(width, height),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
		ClipsDescendants = false,

		-- (collapsed view)
		create "TextButton" {
			Name = "Button",
			Size = UDim2.fromScale(1, 1),

			Text = function()
				return currentLabel()
			end,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = props.textSize or 16,
			Font = props.font or Enum.Font.GothamBold,
			TextColor3 = textColor,

			AutoButtonColor = true,
			Active = not props.disabled,
			Selectable = true,

			BackgroundColor3 = boxBg,
			BackgroundTransparency = boxBgT,

			Corner(radius),
			Stroke(boxStroke, boxStrokeT),

			create "UIPadding" {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			},

			Activated = function()
				if props.disabled then return end
				toggleOpen()
			end,
		},

		-- Popup list (only rendered when open)
		function()
			if not open() then
				return nil
			end

			local visible = math.min(#options, maxVisible)
			local popupH = 16 + (visible * rowHeight) + ((visible - 1) * gap) -- 8 top + 8 bottom padding

			local function optionRow(i, opt)
				local label, optValue, disabled = normalize(opt)

				return create "TextButton" {
					LayoutOrder = i,
					Size = UDim2.new(1, 0, 0, rowHeight),

					Text = label,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = props.textSize or 16,
					Font = props.font or Enum.Font.Gotham,
					TextColor3 = textColor,

					AutoButtonColor = true,
					Active = not disabled,
					Selectable = not disabled,

					BackgroundColor3 = itemBg,
					BackgroundTransparency = itemBgT,

					Corner(itemRadius),

					create "UIPadding" {
						PaddingTop = UDim.new(0, 8),
						PaddingBottom = UDim.new(0, 8),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
					},

					Activated = function()
						if disabled then return end
						set(optValue)
						if closeOnSelect then
							open(false)
							if props.onClose then props.onClose() end
						end
					end,
				}
			end

			return create "Frame" {
				Name = "List",
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.new(0, 0, 1, 8),
				Size = UDim2.new(1, 0, 0, popupH),

				BackgroundColor3 = listBg,
				BackgroundTransparency = listBgT,

				Corner(radius),
				Stroke(listStroke, listStrokeT),

				ClipsDescendants = true,

				create "UIPadding" {
					PaddingTop = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 8),
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				},

				-- Scroll container (works even for small lists)
				create "ScrollingFrame" {
					Name = "Scroll",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,

					ScrollBarThickness = props.scrollBarThickness or 6,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(0, 0, 0, 0),

					create "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						Padding = UDim.new(0, gap),
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					(function()
						local children = {}
						for i, opt in ipairs(options) do
							children[i] = optionRow(i, opt)
						end
						return children
					end)(),
				},
			}
		end,
	}
end
