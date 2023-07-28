--------------------------------------------------------------------------------------------------------------
-- vide/graph.lua
--------------------------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local flags = require(script.Parent.flags)

export type State<T> = typeof(setmetatable(
    {} :: { 
        __cache: T,
        __updated: boolean,
        __derive: (any) -> T,
        __effects:  { [(unknown) -> ()]: unknown } | false, -- weak values
        __children: { State<T> } | false -- weak values
    }, {} :: {
        __concat: (any, any) -> any,
        __add: (any, any) -> any,
        __sub: (any, any) -> any,
        __mul: (any, any) -> any,
        __div: (any, any) -> any,
        --__pow
        --__mod
        --__unm
        --__eq: (unknown, unknown) -> State<boolean>
        --__lt
        --__le
    }
))

export type MaybeState<T> = State<T> | T 
export type Unwrapper = <T>(T) -> T

local WEAK_VALUES_RESIZABLE = { __mode = "vs" }
local EVALUATION_ERR = "error while evaluating state:\n\n"

local State = {} 

local function wrapped(value: any): boolean
    return getmetatable(value) == State
end

local unwrap: <T>(T) -> T;

local checkForYield do
    local t = { __mode = "kv" }
    setmetatable(t, t)

    checkForYield = function(fn: (Unwrapper) -> ())
        t.__unm = function()
            fn(unwrap)
        end
        local ok, err = pcall(function()
            return -t :: any
        end)

        if not ok then
            if err == "attempt to yield across metamethod/C-call boundary" or err == "thread is not yieldable" then
                error(EVALUATION_ERR .. "cannot yield when deriving state in watcher", 3)
            else
                error(EVALUATION_ERR..err, 3)
            end
        end
    end
end

local function setEffect<T>(state: State<unknown>, fn: (T) -> (), key: T)
    if not state.__effects then
        state.__effects = setmetatable({ [fn] = key }, WEAK_VALUES_RESIZABLE) :: any
    else
        state.__effects[fn :: () -> ()] = key
    end
end

local function runEffects(state: State<unknown>)
    if state.__effects then
        for effect, key in next, state.__effects do
            if flags.strict then effect(key) end
            effect(key)
        end 
    end
end

-- retrieves a state's cached value
-- recalculates value if an ancestor was updated
local function get<T>(state: State<T>): T
    if state.__updated then
        state.__updated = false

        if flags.strict then checkForYield(state.__derive) end

        local ok, result: T|string? = pcall(state.__derive, unwrap); if ok then
            rawset(state :: any, "__cache", result :: T)
        else error(EVALUATION_ERR .. result :: string, 0) end 
    end

    return rawget(state :: any, "__cache")
end

-- utility function for retrieving a value from state and allowing passthrough of non-state
unwrap = function<T>(value: MaybeState<T>): T
    if wrapped(value) then
        return get(value :: State<T>)
    else
        return value :: T
    end
end

local function addChild(parent: State<unknown>, child: State<unknown>)
    if parent.__children then
        table.insert(parent.__children, child)    
    else
        parent.__children = setmetatable({ child }, WEAK_VALUES_RESIZABLE) :: any
    end
end

-- marks all state descendants for recalculation and runs effects
local function update(state: State<unknown>)
    runEffects(state)
    if state.__children then
        for _, child in state.__children do
            if not child.__updated then
                child.__updated = true
                update(child)
            end
        end
    end
end

-- sets a state's cached value and updates all descendants
local function set<T>(state: State<T>, value: T)
    state.__cache = value
    update(state)
end

-- links two states as parent-child
local function link(parent: State<unknown>, child: State<unknown>, derive: () -> unknown)
    child.__derive = derive
    addChild(parent, child)
end

-- detect what states were referenced in the given callback and returns them in an array
local function capture<T>(callback: (Unwrapper) -> T): ({ State<unknown> }, T)
    if flags.strict then checkForYield(callback) end

    local states = table.create(2)

    local ok: boolean, result: T|string = pcall(callback, function<T>(value: MaybeState<T>): T
        if wrapped(value) then
            table.insert(states, value :: State<T>)    
            return get(value :: State<T>)  
        else
            return value :: T
        end
    end)

    if not ok then error("error while detecting watcher: " .. result :: string, 0) end

    return states, result :: T
end

-- captures and links any detected states
local function captureAndLink<T>(child: State<T>, callback: (Unwrapper) -> T): T
    local states, value = capture(callback)

    child.__derive = callback
    for _, parent: State<unknown> in next, states do
        addChild(parent, child)
    end

    return value :: T
end

local create: <T>(value: T) -> State<T>

-- factory function for creating operator overloads for shorthands to derive state
local function overload(op: (unknown, unknown) -> unknown): (any, any) -> any
    return function(a: MaybeState<unknown>, b: MaybeState<unknown>): State<unknown>
        local derived: State<unknown> = create(nil :: any)

        local aIsState = wrapped(a)
        local bIsState = wrapped(b)   

        if aIsState and bIsState then
            local function derive() return op(get(a :: State<unknown>), get(b :: State<unknown>)) end
            link(a :: State<unknown>, derived, derive)
            link(b :: State<unknown>, derived, derive)
        elseif aIsState then
            link(a :: State<unknown>, derived, function() return op(get(a :: State<unknown>), b) end)
        else--if bIsState then
            link(b :: State<unknown>, derived, function() return op(a, get(b :: State<unknown>)) end)
        end

        derived.__updated = true
        return derived
    end
end

local function __unm(self: State<unknown>)
    local derived = create(nil :: any)

    link(self, derived, function()
        return -get(self) :: number
    end)

    derived.__updated = true
    return derived
end

local function __index(self: State<unknown>, index: unknown)
    local derived = create(nil :: any)

    link(self, derived, function()
        return (get(self) :: {})[index]
    end)

    derived.__updated = true
    return derived
end

State.__index = __index
State.__concat = overload(function(a: any, b: any) return tostring(a) .. tostring(b) end)
State.__add = overload(function(a: any, b: any) return a + b end)
State.__sub = overload(function(a: any, b: any) return a - b end)
State.__mul = overload(function(a: any, b: any) return a * b end)
State.__div = overload(function(a: any, b: any) return a / b end)
State.__pow = overload(function(a: any, b: any) return a ^ b end)
State.__mod = overload(function(a: any, b: any) return a % b end)
State.__unm = __unm

-- todo: what to do
do
    local function err()
        error("cannot perform equality comparison with state", 2)
    end
    State.__eq = err
    State.__lt = err
    State.__le = err
end


function create<T>(value: T): State<T>
    return setmetatable({
        __cache = value,
        __updated = false,
        __derive  = function() return nil end :: any,
        __effects = false :: false,
        __children = false :: false
    }, State)
end

return table.freeze {
    setEffect = setEffect,
    get = get,
    set = set,
    unwrap = unwrap,
    link = link,
    capture = capture,
    captureAndLink = captureAndLink,
    wrapped = wrapped,
    create = create,
}
