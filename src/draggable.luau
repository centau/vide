-- src/draggable.luau
local UserInputService = game and game:GetService("UserInputService") or nil

-- Factory: injects action from vide
return function(action)
	return function(opts)
		opts = opts or {}
		local axis = opts.axis or "both" -- "x" | "y" | "both"

		return action(function(gui)
			if not UserInputService then
				return
			end
			if typeof(gui) ~= "Instance" or not gui:IsA("GuiObject") then
				return
			end

			local dragging = false
			local dragInput
			local dragStart
			local startPos

			local beganConn
			local inputChangedConn
			local uisConn
			local destroyingConn

			local function disconnectAll()
				if beganConn then beganConn:Disconnect(); beganConn = nil end
				if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
				if uisConn then uisConn:Disconnect(); uisConn = nil end
				if destroyingConn then destroyingConn:Disconnect(); destroyingConn = nil end
			end

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
			end

			beganConn = gui.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = gui.Position

					-- stop dragging when the same input ends
					local changedConn
					changedConn = input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
							if changedConn then
								changedConn:Disconnect()
								changedConn = nil
							end
						end
					end)
				end
			end)

			inputChangedConn = gui.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					dragInput = input
				end
			end)

			uisConn = UserInputService.InputChanged:Connect(function(input)
				if input == dragInput and dragging then
					update(input)
				end
			end)

			-- Cleanup without vide.cleanup which printed false errors into console
			if gui.Destroying then
				destroyingConn = gui.Destroying:Connect(disconnectAll)
			else
				destroyingConn = gui.AncestryChanged:Connect(function(_, parent)
					if parent == nil then
						disconnectAll()
					end
				end)
			end
		end)
	end
end
