-- src/tween.luau
local TweenService = game and game:GetService("TweenService") or nil
local HasTweenInfo = (TweenInfo ~= nil)

--cleanup and action injection so tweens are stopped on scope destruction

return function(action, cleanup)
	local tween = {}

	-- Presets: only available when TweenInfo exists (Roblox runtime)
	if HasTweenInfo then
		tween.presets = {
			instant = TweenInfo.new(0),
			fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			smooth = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			snappy = TweenInfo.new(0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		}
	else
		tween.presets = {}
	end

	-- Imperative helper: plays a tween (or applies instantly in tests)
	function tween.tweenTo(instance, goals, info)
		if not instance or not goals then
			return nil
		end

		-- Non-Roblox / unit tests: apply instantly
		if not TweenService then
			for k, v in pairs(goals) do
				instance[k] = v
			end
			return nil
		end


		local tweenInfo = info
		if tweenInfo == nil then
			if tween.presets.smooth then
				tweenInfo = tween.presets.smooth
			else
				-- Fallback in case presets are not available for any reason
				tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end
		end

		local tw = TweenService:Create(instance, tweenInfo, goals)
		tw:Play()
		return tw
	end

	-- Action helper: attach tweening in create() trees
	function tween.tween(goals, info)
		return action(function(instance)
			if not goals then
				return
			end

			-- Non-Roblox / unit tests: apply instantly
			if not TweenService then
				for k, v in pairs(goals) do
					instance[k] = v
				end
				return
			end

			local tweenInfo = info
			if tweenInfo == nil then
				if tween.presets.smooth then
					tweenInfo = tween.presets.smooth
				else
					tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				end
			end

			local tw = TweenService:Create(instance, tweenInfo, goals)
			tw:Play()

			-- Ensure tween is cancelled when the scope is destroyed
			cleanup(function()
				pcall(function()
					tw:Cancel()
				end)
			end)
		end)
	end

	return tween
end
