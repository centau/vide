------------------------------------------------------------------------------------------
-- vide/wrap.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
type MaybeState<T> = graph.MaybeState<T>
local create = graph.create
local get = graph.get
local set = graph.set
local wrapped = graph.wrapped

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)

type Setter<T> = (value: MaybeState<T> | (MaybeState<T>) -> MaybeState<T>, force: boolean?) -> T

local function wrap<T>(value: MaybeState<T>?): (State<T>, Setter<T>)
    local state = create(if wrapped(value) then get(value :: State<T>) else value :: T)

    local function setter(vi: MaybeState<T> | (MaybeState<T>) -> MaybeState<T>, force: boolean?): T
        if type(vi) == "function" then
            vi = vi(get(state))
        end

        local v = if wrapped(vi) then get(vi :: State<T>) else vi :: T

        if v ~= state.__cache or force then
            set(state, v)
        elseif flags.strict and type(v) == "table" then
            throw("attempt to set same table object")   
        end

        return v
    end

    return state, setter 
end

return wrap
