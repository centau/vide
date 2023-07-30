--------------------------------------------------------------------------------------------------------------
-- vide/watch.lua
--------------------------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
local set_effect = graph.set_effect
local capture = graph.capture

local function watch(effect: () -> ()): () -> ()
    -- todo: call cleanup on initial debug call when strict
    local nodes, cleanup = capture(effect :: () -> (() -> ()?))

    nodes = table.clone(nodes)

    local function fn()
        if cleanup then cleanup(); cleanup = nil end
        cleanup = effect()
    end

    for _, node in next, nodes do
        set_effect(node, fn, true)  
    end

    local function unwatch()
        for _, node in next, nodes do
            set_effect(node, fn, nil)    
        end
        if cleanup then cleanup(); cleanup = nil end
    end

    return unwatch
end

return watch
