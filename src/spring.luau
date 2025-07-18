local graph = require "./graph"
type Node<T> = graph.Node<T>
type SourceNode<T> = graph.SourceNode<T>
local create_node = graph.create_node
local create_source_node = graph.create_source_node
local assert_stable_scope = graph.assert_stable_scope
local evaluate_node = graph.evaluate_node
local update_descendants = graph.update_descendants
local push_scope_as_child_of = graph.push_scope_as_child_of

local UPDATE_RATE = 120
local TOLERANCE = 0.001
local TOLERANCE_VECTOR = vector.create(TOLERANCE, TOLERANCE, TOLERANCE)

type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3

--[[
Unsupported datatypes:
- bool
- Vector2int16
- Vector3int16
- EnumItem
]]

type SpringState<T> = {
    k: number, -- spring constant
    c: number, -- damping coeff

    x0_123: vector, x0_456: vector, -- current position
    x1_123: vector, x1_456: vector, -- target position
    v_123: vector, v_456: vector, -- current velocity

    source_value: T -- current value of spring input source
}

type SpringSettings<T> = ({
    position: T?,
    velocity: T?,
    impulse: T?
}) -> ()

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
        -- todo: hsv, oklab?
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

local invalid_type = {
    __index = function(_, t: string)
        error(`cannot spring type {t}`, 0)
    end
}

setmetatable(type_to_vec6, invalid_type)
setmetatable(vec6_to_type, invalid_type)

-- maps spring data to its corresponding output node
-- lifetime of spring data is tied to output node
local springs: { [SpringState<unknown>]: SourceNode<unknown> } = {}
setmetatable(springs :: any, { __mode = "v" })

local function spring<T>(source: () -> T, period: number?, damping_ratio: number?): (() -> T, SpringSettings<T>)
    local owner = assert_stable_scope()

    -- https://en.wikipedia.org/wiki/Damping

    local w_n = 2*math.pi / (period or 1)
    local z = damping_ratio or 1

    local k = w_n^2
    local c_c = 2*w_n
    local c = z * c_c

    -- todo: is there a solution other than reducing step size?
    -- todo: this does not catch all solver exploding cases
    if c > UPDATE_RATE*2 then -- solver will explode if this is true
        error("spring damping too high, consider reducing damping or increasing period", 0)
    end

    local data: SpringState<T> = {
        k = k,
        c = c,

        x0_123 = vector.zero,
        x1_123 = vector.zero,
        v_123 = vector.zero,

        x0_456 = vector.zero,
        x1_456 = vector.zero,
        v_456 = vector.zero,

        source_value = false :: any,
    }
    
    local output = create_source_node(false :: any)

    local function updater_effect()
        local value = source()
        data.x1_123, data.x1_456 = type_to_vec6[typeof(value)](value)
        data.source_value = value
        springs[data] = output
        return value
    end

    local updater = create_node(owner, updater_effect, false :: any)

    evaluate_node(updater)

    -- set initial position to goal
    data.x0_123, data.x0_456 = data.x1_123, data.x1_456

    -- set output to goal
    output.cache = data.source_value

    local config = function(p)
        local x = p.position
        local v = p.velocity
        local dv = p.impulse

        if x then
            data.x0_123, data.x0_456 = type_to_vec6[typeof(x)](x)
        end

        if v then
            data.v_123, data.v_456 = type_to_vec6[typeof(v)](v)
        end

        if dv then
            local dv_123, dv_456 = type_to_vec6[typeof(dv)](dv)
            data.v_123 += dv_123
            data.v_456 += dv_456
        end

        springs[data] = output
    end :: SpringSettings<T>

    return function(...)
        if select("#", ...) == 0 then -- no args were given
            push_scope_as_child_of(output)
            return output.cache
        end

        -- set current position to value
        local v = ... :: T
        data.x0_123, data.x0_456 = type_to_vec6[typeof(v)](v)

        -- reset velocity
        data.v_123 = vector.zero
        data.v_456 = vector.zero

        -- schedule spring
        springs[data] = output

        -- set output to value
        output.cache = v

        return v
    end, config
end

local function step_springs(dt: number)
    for data in next, springs do
        local k, c,
        x0_123, x1_123, u_123,
        x0_456, x1_456, u_456 =
            data.k, data.c,
            data.x0_123, data.x1_123, data.v_123,
            data.x0_456, data.x1_456, data.v_456

        -- calculate displacement from target
        local dx_123 = x0_123 - x1_123
        local dx_456 = x0_456 - x1_456

        -- calculate spring force
        local fs_123 = dx_123*-k
        local fs_456 = dx_456*-k

        -- calculate friction force
        local ff_123 = u_123*-c
        local ff_456 = u_456*-c

        -- calculate acceleration step
        local dv_123 = (fs_123 + ff_123)*dt
        local dv_456 = (fs_456 + ff_456)*dt

        -- apply acceleration step
        local v_123 = u_123 + dv_123
        local v_456 = u_456 + dv_456

        -- calculate new position
        local x_123 = x0_123 + v_123*dt
        local x_456 = x0_456 + v_456*dt

        data.x0_123, data.x0_456 = x_123, x_456
        data.v_123, data.v_456 = v_123, v_456
    end
end

local function update_spring_sources()
    for data, output in springs do
        local x0_123, x1_123, v_123,
        x0_456, x1_456, v_456 =
            data.x0_123, data.x1_123, data.v_123,
            data.x0_456, data.x1_456, data.v_456

        local max_difference = vector.max(
            vector.abs(x0_123 - x1_123 :: any),
            vector.abs(x0_456 - x1_456 :: any),
            vector.abs(v_123 :: any),
            vector.abs(v_456 :: any),
            TOLERANCE_VECTOR
        )

        if max_difference == TOLERANCE_VECTOR then
            -- close enough to target, unshedule spring and set value to target
            springs[data] = nil
            output.cache = data.source_value
        else
            output.cache = vec6_to_type[typeof(data.source_value)](x0_123, x0_456)
        end

        update_descendants(output)
    end
end

return function()
    local time_elapsed = 0

    return spring, function(dt: number)
        time_elapsed += dt

        while time_elapsed > 1 / UPDATE_RATE do
            time_elapsed -= 1 / UPDATE_RATE
            step_springs(1 / UPDATE_RATE)
        end

        update_spring_sources()
    end
end
