--------------------------------------------------------------------------------------------------------------
-- vide/spring.lua
--------------------------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

--[[
    Spring animation library adapted from RDL::spring v1.0

    Supported datatypes:
    *number
    !bool
    *CFrame
    ?Rect
    *Color3
    *UDim
    *UDim2
    *Vector2
    !Vector2int16
    *Vector3
    !Vector3int16
    !EnumItem
]]

local throw = require(script.Parent.throw)

local graph = require(script.Parent.graph)
local create = graph.create
local get = graph.get
local set = graph.set

type Node<T> = graph.Node<T>

type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3

type SpringData<T> = {
    alpha: number,
    duration: number,
    period: number,
    damping_ratio: number,
    velocity: number,
    initial_velocity: number,
    initial_position: T,
    target_position: T,
    target: () -> T
}

type Lerp<T> = (initial: T, target: T, alpha: number) -> T

local function solve(T: number, z: number, u: number, t: number): number -- alpha
    local wn = 2*math.pi / T
    local wd = wn * math.sqrt(1 - z^2)
    local a = z * wn

    local s = math.exp(-a*t) * math.cos(wd*t)
    local v = (u/wn) * math.exp(-a*t) * math.sin(wn*t)
    return (1-s) + v
end

local lerpable: { [string]: Lerp<any> } = {
    number = function(v1, v2, a)
        return v1 + (v2 - v1)*a
    end :: Lerp<number>,

    CFrame = function(v1, v2, a)
        return v1:Lerp(v2, a)
    end :: Lerp<CFrame>,

    Color3 = function(v1, v2, a) 
        return v1:Lerp(v2, a)
    end :: Lerp<Color3>,

    UDim = function(v1, v2, a) 
        return UDim.new(
            v1.Scale + (v2.Scale - v1.Scale)*a,
            v1.Offset + (v2.Offset - v1.Offset)*a
        )
    end :: Lerp<UDim>,

    UDim2 = function(v1, v2, a)
        return v1:Lerp(v2, a)
    end :: Lerp<UDim2>,

    Vector2 = function(v1, v2, a)
        return v1:Lerp(v2, a)
    end :: Lerp<Vector2>,

    Vector3 = function(v1, v2, a)
        return v1:Lerp(v2, a)
    end :: Lerp<Vector3>,
}

local springs: { [SpringData<any>]: Node<any> } = {}
setmetatable(springs, { __mode = "vs" })

local function spring<T>(target: () -> T, period: number, damping_ratio: number?): () -> T
    local initial_position = target()
    local node = create(initial_position)

    local data: SpringData<T> = {
        alpha = 0,
        duration = 0,
        period = period,
        damping_ratio = damping_ratio or 1,
        velocity = 0,
        initial_velocity = 0,
        initial_position = initial_position,
        target_position = initial_position,
        target = target
    }

    springs[data] = node

    return function()
        return get(node)
    end
end

local function update_springs(dt: number)
    for data, output in next, springs do
        if data.target() ~= data.target_position then
            data.target = data.target()
            data.initial_position = get(output)
            data.alpha = 0
            data.duration = 0
            data.initial_velocity = data.velocity
        end

        local initial_position: Animatable = data.initial_position
        local target_position: Animatable = data.target_position
        local target_type: string = typeof(target_position)

        if target_type ~= typeof(initial_position) then 
            springs[data] = nil
            warn(string.format(
                "Mismatched state value types, cancelling state update (initial value: %s, target value: %s)",
                typeof(initial_position),
                target_type
            ))
            throw(`Cannot tween type { typeof(initial_position) } and { target_type }`)
            continue
        end

        local lerp: Lerp<Animatable> = lerpable[target_type]

        if lerp == nil then 
            springs[data] = nil
            throw(`Cannot animate type { target_type }`)
            continue
        end

        local new_time = data.duration + dt
        local new_alpha = solve(data.period, data.damping_ratio, data.initial_velocity, new_time)

        data.velocity = -(new_alpha - data.alpha)/dt
        data.alpha = new_alpha
        data.duration = new_time

        local value = lerp(initial_position, target_position, new_alpha)

        set(output, value)
    end
end

return function() return spring, update_springs end
