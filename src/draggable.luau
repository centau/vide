-- vide/draggable.luau
local UserInputService = game:GetService("UserInputService")

return function(action, cleanup)
	return function(opts)
		opts = opts or {}
		local axis = opts.axis or "both" -- "x" | "y" | "both"

		return action(function(gui)
			local dragging = false
			local dragInput
			local dragStart
			local startPos

			local function update(input)
				local delta = input.Position - dragStart

				local xOff = startPos.X.Offset
				local yOff = startPos.Y.Offset

				if axis == "x" or axis == "both" then
					xOff = startPos.X.Offset + delta.X
				end
				if axis == "y" or axis == "both" then
					yOff = startPos.Y.Offset + delta.Y
				end

				gui.Position = UDim2.new(startPos.X.Scale, xOff, startPos.Y.Scale, yOff)

				if opts.onDrag then
					opts.onDrag(gui.Position)
				end
			end

			local beganConn = gui.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = gui.Position

					if opts.onDragStart then
						opts.onDragStart(startPos)
					end

					local changedConn
					changedConn = input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
							if changedConn then changedConn:Disconnect() end
							if opts.onDragEnd then
								opts.onDragEnd(gui.Position)
							end
						end
					end)

					cleanup(function()
						if changedConn then changedConn:Disconnect() end
					end)
				end
			end)

			local changedConn = gui.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					dragInput = input
				end
			end)

			local uisConn = UserInputService.InputChanged:Connect(function(input)
				if input == dragInput and dragging then
					update(input)
				end
			end)

			cleanup(function()
				beganConn:Disconnect()
				changedConn:Disconnect()
				uisConn:Disconnect()
			end)
		end)
	end
end
