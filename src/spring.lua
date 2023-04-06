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
type State<T> = graph.State<T>
type MaybeState<T> = graph.MaybeState<T>
local create = graph.create
local get = graph.get
local set = graph.set
local unwrap = graph.unwrap
local wrapped = graph.wrapped

type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3

type SpringData<T> = {
    Alpha: number;
    Duration: number;
    Period: number;
    Damping: number;
    Velocity: number;
    InitialVelocity: number;
    Initial: T;
    Target: T;
    Input: State<T>;
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

local activeSprings: { [State<any>]: SpringData<any> } = {}
setmetatable(activeSprings, { __mode = "ks" })

local function spring<T>(input: MaybeState<T>, period: number, damping: number?): State<T>
    local initial = unwrap(input) :: T
    local output = create(initial)

    local springData: SpringData<T> = {
        Alpha = 0,
        Duration = 0,
        Period = period,
        Damping = damping or 1,
        Velocity = 0,
        InitialVelocity = 0,
        Initial = initial,
        Target = initial,
        Input = input :: any,
        LastInput = initial,
        LastOutput = initial
    }

    activeSprings[output] = springData

    return output
end

local function updateSprings(dt: number)
    for node, data in next, activeSprings do
        local currentTarget = get(data.Input)
        if currentTarget ~= data.Target then
            data.Target = currentTarget
            data.Initial = get(node)
            data.Target = get(data.Input)
            data.Alpha = 0
            data.Duration = 0
            data.InitialVelocity = data.Velocity
        end

        local initial: Animatable = data.Initial
        local target: Animatable = data.Target
        local targetType: string = typeof(target)

        if targetType ~= typeof(initial) then 
            activeSprings[node] = nil
            warn(string.format(
                "Mismatched state value types, cancelling state update (initial value: %s, target value: %s)",
                typeof(initial),
                targetType
            ))
            throw(`Cannot tween type { typeof(initial) } and { targetType }`)
            continue
        end

        local lerp: Lerp<Animatable> = lerpable[targetType]

        if lerp == nil then 
            activeSprings[node] = nil
            throw(`Cannot animate type { targetType }`)
            continue
        end

        local newTime = data.Duration + dt
        local newAlpha = solve(data.Period, data.Damping, data.InitialVelocity, newTime)

        data.Velocity = -(newAlpha - data.Alpha)/dt
        data.Alpha = newAlpha
        data.Duration = newTime

        local value = lerp(initial, target, newAlpha)

        set(node, value)
    end
end

return function() return spring, updateSprings end
