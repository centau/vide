-- vide/slider.luau
local UserInputService = game:GetService("UserInputService")

local function clamp(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function invLerp(a, b, v)
	if a == b then return 0 end
	return (v - a) / (b - a)
end

local function quantize(v, step)
	if not step or step <= 0 then return v end
	return math.floor((v / step) + 0.5) * step
end

-- Factory: inject Vide functions to avoid cyclic requires
return function(create, source, action, cleanup)
	return function(props)
		props = props or {}

		local minV = props.min or 0
		local maxV = props.max or 1
		local step = props.step
		local value = props.value
		assert(value, "vide.slider: props.value (source<number>) is required")

		local theme = props.theme or {}
		local format = props.format or function(v) return tostring(v) end
		local onChanged = props.onChanged

		local trackRef = source(nil)

		local function setFromX(screenX)
			local track = trackRef()
			if not track then return end

			local absPosX = track.AbsolutePosition.X
			local absSizeX = track.AbsoluteSize.X
			if absSizeX <= 0 then return end

			local t = clamp((screenX - absPosX) / absSizeX, 0, 1)
			local v = lerp(minV, maxV, t)
			v = quantize(v, step)

			value(v)
			if onChanged then onChanged(v) end
		end

		return create "Frame" {
			Name = props.name or "Slider",
			Size = props.size or UDim2.fromOffset(516, 90),
			Position = props.position,
			AnchorPoint = props.anchorPoint,
			LayoutOrder = props.layoutOrder,
			BackgroundTransparency = 1,

			create "TextLabel" {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(516, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = props.fontFace,
				TextSize = props.labelTextSize or 16,
				TextColor3 = props.labelTextColor or Color3.fromRGB(235, 238, 245),
				Text = props.label or "Slider",
			},

			create "TextLabel" {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(516, 24),
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = props.fontFace,
				TextSize = props.valueTextSize or 16,
				TextColor3 = props.valueTextColor or Color3.fromRGB(200, 206, 220),
				Text = function()
					return format(value())
				end,
			},

			create "Frame" {
				Name = "Track",
				Position = UDim2.fromOffset(0, 38),
				Size = UDim2.fromOffset(516, 16),
				BackgroundColor3 = theme.trackColor or Color3.fromRGB(20, 22, 28),
				BackgroundTransparency = theme.trackTransparency or 0.15,

				action(function(track)
					trackRef(track)

					local trackBeganConn = track.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							setFromX(input.Position.X)
						end
					end)

					cleanup(function()
						if trackRef() == track then trackRef(nil) end
						trackBeganConn:Disconnect()
					end)
				end),

				create "UICorner" { CornerRadius = UDim.new(0, theme.cornerRadius or 8) },
				create "UIStroke" {
					Thickness = 1,
					Color = theme.strokeColor or Color3.fromRGB(255, 255, 255),
					Transparency = theme.strokeTransparency or 0.8,
				},

				create "Frame" {
					Name = "Fill",
					Size = function()
						local t = clamp(invLerp(minV, maxV, value()), 0, 1)
						return UDim2.fromScale(t, 1)
					end,
					BackgroundColor3 = theme.fillColor or Color3.fromRGB(80, 140, 255),
					BackgroundTransparency = theme.fillTransparency or 0.15,
					create "UICorner" { CornerRadius = UDim.new(0, theme.cornerRadius or 8) },
				},

				create "TextButton" {
					Name = "Knob",
					AutoButtonColor = false,
					Text = "",
					Size = UDim2.fromOffset(24, 24),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = function()
						local t = clamp(invLerp(minV, maxV, value()), 0, 1)
						return UDim2.fromScale(t, 0.5)
					end,
					BackgroundColor3 = theme.knobColor or Color3.fromRGB(235, 238, 245),
					BackgroundTransparency = theme.knobTransparency or 0,

					create "UICorner" { CornerRadius = UDim.new(0, theme.knobRadius or 999) },
					create "UIStroke" { Thickness = 1, Color = Color3.fromRGB(0, 0, 0), Transparency = 0.75 },

					action(function(btn)
						local dragInput
						local dragging = false
						local beganConn
						local changedConn
						local uisChangedConn

						local function update(input)
							setFromX(input.Position.X)
						end

						beganConn = btn.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								dragging = true
								update(input)

								changedConn = input.Changed:Connect(function()
									if input.UserInputState == Enum.UserInputState.End then
										dragging = false
									end
								end)
							end
						end)

						btn.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								dragInput = input
							end
						end)

						uisChangedConn = UserInputService.InputChanged:Connect(function(input)
							if input == dragInput and dragging then
								update(input)
							end
						end)

						cleanup(function()
							if beganConn then beganConn:Disconnect() end
							if changedConn then changedConn:Disconnect() end
							if uisChangedConn then uisChangedConn:Disconnect() end
						end)
					end),
				},
			},
		}
	end
end
