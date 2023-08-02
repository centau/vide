if not game then script = (require :: any) "test/wrap-require" end

local memoize = require(script.Parent.memoize)
local bind = require(script.Parent.bind)

local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
type MaybeState<T> = graph.MaybeState<T>
local create = graph.create
local get = graph.get
local link = graph.link
local wrapped = graph.wrapped

local Types = require(script.Parent.Types)

type Listener = (unknown) -> ()

local getChangeSymbol = memoize(function(name: string): Types.Symbol<MaybeState<Listener>>
    return {
        priority = 2,
        run = function(instance: Instance, listener: MaybeState<Listener>)
            local event: RBXScriptSignal<nil> = instance:GetPropertyChangedSignal(name)

            if type(listener) == "function" then
                event:Connect(function()
                    listener( (instance :: any)[name] )
                end)
            elseif wrapped(listener) then
                local state = create(nil)

                link(listener :: State<Listener>, state, function() 
                    local newListener = get(listener :: State<Listener>)
                    return newListener and function()
                        newListener( (instance :: any)[name] )
                    end
                end)

                state.__updated = true
                bind.event(state :: State<any>, instance, event)
            else 
                error("Attempt to connect non-function to changed event", 2)
            end
        end
    }
end)

local Changed = table.freeze(setmetatable({}, {__index = function(_, index: string)
    return getChangeSymbol(index)
end})) :: any

return Changed :: { [string]: unknown }
