if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local set_effect = graph.set_effect
local capture = graph.capture

local function watch(effect: () -> ()): () -> ()
    local nodes = capture(effect :: () -> nil)

    -- store aside captured nodes in new table
    nodes = table.clone(nodes)

    -- register effect with permanent lifetime
    for _, node in next, nodes do
        set_effect(node, effect, true)  
    end

    local function unwatch()
        -- unregister effect from all nodes
        for _, node in next, nodes do
            set_effect(node, effect, nil)    
        end
    end

    return unwatch
end

return watch
