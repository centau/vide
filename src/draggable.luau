-- src/draggable.luau
local UserInputService = game and game:GetService("UserInputService") or nil

return function(action)
	return function(opts)
		opts = opts or {}
		local axis = opts.axis or "both" -- "x" | "y" | "both"
		local smoothTime = tonumber(opts.smoothTime) or 0 -- seconds; 0 = off

		return action(function(gui)
			if not UserInputService then return end
			if typeof(gui) ~= "Instance" or not gui:IsA("GuiObject") then return end

			local dragging = false
			local dragInput
			local dragStart
			local startPos

			local beganConn
			local inputChangedConn
			local uisConn
			local destroyingConn

			-- smoothing state (offset-space)
			local currentX, currentY
			local targetX, targetY
			local lastT = os.clock()

			local function disconnectAll()
				if beganConn then beganConn:Disconnect(); beganConn = nil end
				if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
				if uisConn then uisConn:Disconnect(); uisConn = nil end
				if destroyingConn then destroyingConn:Disconnect(); destroyingConn = nil end
			end

			local function setPosition(xOff, yOff)
				gui.Position = UDim2.new(startPos.X.Scale, xOff, startPos.Y.Scale, yOff)
			end

			local function updateTarget(input)
				local delta = input.Position - dragStart

				local xOff = startPos.X.Offset
				local yOff = startPos.Y.Offset

				if axis == "x" or axis == "both" then
					xOff = startPos.X.Offset + delta.X
				end
				if axis == "y" or axis == "both" then
					yOff = startPos.Y.Offset + delta.Y
				end

				targetX, targetY = xOff, yOff

				-- init current on first target
				if currentX == nil then
					currentX, currentY = targetX, targetY
				end
			end

			local function step()
				if not dragging or not dragInput then return end
				if smoothTime <= 0 then
					setPosition(targetX, targetY)
					return
				end

				local now = os.clock()
				local dt = now - lastT
				lastT = now

				-- alpha in [0..1]
				local alpha = 1 - math.exp(-dt / smoothTime)

				currentX = currentX + (targetX - currentX) * alpha
				currentY = currentY + (targetY - currentY) * alpha

				setPosition(currentX, currentY)
			end

			beganConn = gui.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = gui.Position

					-- reset smoothing state
					currentX, currentY, targetX, targetY = nil, nil, nil, nil
					lastT = os.clock()

					updateTarget(input)

					local changedConn
					changedConn = input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
							if changedConn then changedConn:Disconnect(); changedConn = nil end
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
					updateTarget(input)
					step()
				end
			end)

			if gui.Destroying then
				destroyingConn = gui.Destroying:Connect(disconnectAll)
			else
				destroyingConn = gui.AncestryChanged:Connect(function(_, parent)
					if parent == nil then disconnectAll() end
				end)
			end
		end)
	end
end
