-- src/tween.luau
local TweenService = game and game:GetService("TweenService") or nil

-- Factory: inject action + cleanup so tweens are stopped on scope destruction
return function(action, cleanup)
	local tween = {}

	-- Presets (simple, useful)
	tween.presets = {
		instant = TweenInfo.new(0),
		fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		smooth = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		snappy = TweenInfo.new(0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	}

	-- Imperative helper (for events): vide.tweenTo(instance, {Position=...}, info)
	function tween.tweenTo(instance, goals, info)
		if not TweenService then
			-- Non-Roblox / tests: just apply instantly
			if instance and goals then
				for k, v in pairs(goals) do
					instance[k] = v
				end
			end
			return nil
		end

		local tweenInfo = info or tween.presets.smooth
		local tw = TweenService:Create(instance, tweenInfo, goals)
		tw:Play()
		return tw
	end

	-- Action helper (for create trees):
	-- create "Frame" { tween({Position=...}, presets.fast), ... }
	function tween.tween(goals, info)
		return action(function(instance)
			if not goals then
				return
			end

			-- If TweenService not available, apply instantly (tests outside of roblox environment)
			if not TweenService then
				for k, v in pairs(goals) do
					instance[k] = v
				end
				return
			end

			local tweenInfo = info or tween.presets.smooth
			local tw = TweenService:Create(instance, tweenInfo, goals)
			tw:Play()

			-- Stop on scope destruction to avoid leaking connections/tweens
			cleanup(function()
				pcall(function()
					tw:Cancel()
				end)
			end)
		end)
	end

	return tween
end
