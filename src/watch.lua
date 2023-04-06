--------------------------------------------------------------------------------------------------------------
-- vide/watch.lua
--------------------------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
type Unwrapper = graph.Unwrapper
local setEffect = graph.setEffect
local capture = graph.capture
local unwrap = graph.unwrap

local function watch(effect: (Unwrapper) -> ()): () -> ()
    local states, cleanup = capture(effect :: () -> (() -> ()?))

    local function fn()
        if cleanup then cleanup(); cleanup = nil end
        cleanup = effect(unwrap)
    end

    for _, state in next, states do
        setEffect(state, fn, true)  
    end

    local function unwatch()
        for _, state in next, states do
            setEffect(state, fn, nil)    
        end
        if cleanup then cleanup(); cleanup = nil end
    end

    return unwatch
end

return watch
