local easings = require "./easings"

export type TweenConfig = {
	time: number?,
	style: easings.EasingFunction?,
	delay: number?,
	reverses: boolean?,
	repeat_count: number?,
}

local graph = require "./graph"
type Node<T> = graph.Node<T>
type SourceNode<T> = graph.SourceNode<T>
local create_node = graph.create_node
local create_source_node = graph.create_source_node
local assert_stable_scope = graph.assert_stable_scope
local evaluate_node = graph.evaluate_node
local update_descendants = graph.update_descendants
local push_scope_as_child_of = graph.push_scope_as_child_of

type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3 | Rect | { number }

--[[
Unsupported datatypes:
- bool
- Vector2int16
- Vector3int16
- EnumItem
]]

type TweenState<T> = {
	time: number,
	style: easings.EasingFunction,
	delay: number,
	reverses: boolean,
	repeat_count: number,
	time_passed: number,

	x0_123: vector, x0_456: vector, -- start position
	x1_123: vector, x1_456: vector, -- target position

	source_value: T -- current value of tween input source
}

type TypeToVec6<T> = (T) -> (vector, vector)
type Vec6ToType<T> = (vector, vector) -> T

local type_to_vec6 = {
	number = function(v)
        return vector.create(v, 0, 0), vector.zero
    end :: TypeToVec6<number>,

	CFrame = function(v)
        return v.Position, vector.create(v:ToEulerAnglesXYZ())
    end :: TypeToVec6<CFrame>,

	Color3 = function(v)
        return vector.create(v.R, v.G, v.B), vector.zero
    end :: TypeToVec6<Color3>,

	UDim = function(v)
        return vector.create(v.Scale, v.Offset, 0), vector.zero
    end :: TypeToVec6<UDim>,

	UDim2 = function(v)
        return vector.create(v.X.Scale, v.X.Offset, v.Y.Scale), vector.create(v.Y.Offset, 0, 0)
    end :: TypeToVec6<UDim2>,

	Vector2 = function(v)
        return vector.create(v.X, v.Y, 0), vector.zero
    end :: TypeToVec6<Vector2>,

	Vector3 = function(v)
        return v, vector.zero
    end :: TypeToVec6<Vector3>,

	Rect = function(v)
        return vector.create(v.Min.X, v.Min.Y, v.Max.X), vector.create(v.Max.Y, 0, 0)
    end :: TypeToVec6<Rect>,

	table = function(v)
        return vector.create(v[1] or 0, v[2] or 0, v[3] or 0), vector.create(v[4] or 0, 0, 0)
    end :: TypeToVec6<{ number }>
}

local vec6_to_type = {
	number = function(a, b)
        return a.X
    end :: Vec6ToType<number>,

	CFrame = function(a, b)
        return CFrame.new(a) * CFrame.fromEulerAnglesXYZ(b.X, b.Y, b.Z)
    end :: Vec6ToType<CFrame>,

	Color3 = function(v)
        return Color3.new(math.clamp(v.X, 0, 1), math.clamp(v.Y, 0, 1), math.clamp(v.Z, 0, 1))
    end :: Vec6ToType<Color3>,

	UDim = function(v)
        return UDim.new(v.X, math.round(v.Y))
    end :: Vec6ToType<UDim>,

	UDim2 = function(a, b)
        return UDim2.new(a.X, math.round(a.Y), a.Z, math.round(b.X))
    end :: Vec6ToType<UDim2>,

	Vector2 = function(v)
        return Vector2.new(v.X, v.Y)
    end :: Vec6ToType<Vector2>,

	Vector3 = function(v)
        return v
    end :: Vec6ToType<Vector3>,

	Rect = function(a, b)
        return Rect.new(a.X, a.Y, a.Z, b.X)
    end :: Vec6ToType<Rect>,

	table = function(a, b)
        return { a.X, a.Y, a.Z, b.X }
    end :: Vec6ToType<{ number }>
}

local invalid_type = { __index = function(_, t: string) error(`cannot tween type {t}`, 0) end }
setmetatable(type_to_vec6, invalid_type)
setmetatable(vec6_to_type, invalid_type)

local tweens: { [TweenState<unknown>]: SourceNode<unknown> } = {}
setmetatable(tweens :: any, { __mode = "v" })

local function tween<T>(source: () -> T, config: TweenConfig?): () -> T
	local owner = assert_stable_scope()

	local data: TweenState<T> = {
		time         = (config and config.time) or 1,
		style        = (config and config.style) or easings.quad_ease_out,
		delay        = (config and config.delay) or 0,
		reverses     = (config and config.reverses) or false,
		repeat_count = (config and config.repeat_count) or 0,
		time_passed  = 0,
		x0_123 = vector.zero, x0_456 = vector.zero,
		x1_123 = vector.zero, x1_456 = vector.zero,
		source_value = false :: any,
	}

	local output = create_source_node(false :: any)

	local function updater_effect()
		local value = source()
		local x1_123, x1_456 = type_to_vec6[typeof(value)](value)

		local current_val = output.cache or value
		local x0_123, x0_456 = type_to_vec6[typeof(current_val)](current_val)

		data.x0_123, data.x0_456 = x0_123, x0_456
		data.x1_123, data.x1_456 = x1_123, x1_456

		data.time_passed = 0
		data.source_value = value

		tweens[data] = output
		return value
	end

	local updater = create_node(owner, updater_effect, false :: any)
	evaluate_node(updater)

	output.cache = data.source_value

	return function(...)
		if select("#", ...) == 0 then
			push_scope_as_child_of(output)
			return output.cache
		end

		local v = ... :: T
		data.x1_123, data.x1_456 = type_to_vec6[typeof(v)](v)
		data.x0_123, data.x0_456 = data.x1_123, data.x1_456
		tweens[data] = nil
		output.cache = v
		return v
	end
end

local function update_tween_sources(dt: number)
    for data, output in tweens do
        data.time_passed += dt

        local duration = data.time
        local delay = data.delay
        local reverses = data.reverses
        local repeat_count = data.repeat_count

        -- The duration of one full "cycle" (forward + optional back)
        local cycle_duration = if reverses then duration * 2 else duration
        local total_time = data.time_passed - delay

        if total_time < 0 then continue end

        -- Calculate how many cycles have finished
        local current_cycle = math.floor(total_time / cycle_duration)

        -- Check for completion (if not infinite repeat)
        if repeat_count ~= -1 and current_cycle > repeat_count then
            tweens[data] = nil
            output.cache = data.source_value
        else
            -- Time relative to the start of the current cycle
            local time_in_cycle = total_time % cycle_duration
            local alpha

            if reverses then
                if time_in_cycle <= duration then
                    alpha = time_in_cycle / duration
                else
                    alpha = 1 - ((time_in_cycle - duration) / duration)
                end
            else
                alpha = time_in_cycle / duration
            end

            local eased_alpha = data.style(math.clamp(alpha, 0, 1))

            local x_123 = data.x0_123 + (data.x1_123 - data.x0_123) * eased_alpha
            local x_456 = data.x0_456 + (data.x1_456 - data.x0_456) * eased_alpha

            output.cache = vec6_to_type[typeof(data.source_value)](x_123, x_456)
        end

        update_descendants(output)
    end
end

return function()
	return tween, function(dt: number)
		update_tween_sources(dt)
	end
end
