------------------------------------------------------------------------------------------
-- vide/Event.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local memoize = require(script.Parent.memoize)
local bind = require(script.Parent.bind)

local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
type MaybeState<T> = graph.MaybeState<T>
local wrapped = graph.wrapped

local Types = require(script.Parent.Types)

type Listener = (unknown) -> ()

local getEventSymbol = memoize(function(name: string): Types.Symbol<MaybeState<Listener>>
    return {
        priority = 2,
        run = function(instance: Instance, listener: MaybeState<Listener>)
            local event: RBXScriptSignal<...unknown> = (instance :: any)[name]

            if type(listener) == "function" then
                event:Connect(listener)
            elseif wrapped(listener) then
                bind.event(listener :: State<Listener>, instance, event)
            else 
                error("Attempt to connect non-function to event", 2)
            end
        end
    }
end)

local Event = table.freeze(setmetatable({}, {__index = function(_, index: string)
    return getEventSymbol(index)
end})) :: any

return Event :: { [string]: unknown }

