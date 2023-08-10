if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local set_effect = graph.set_effect
local capture = graph.capture

local function watch(effect: () -> ()): () -> ()
    local nodes = capture(effect :: () -> nil)

    nodes = table.clone(nodes)

    for _, node in next, nodes do
        set_effect(node, effect, true)  
    end

    local function unwatch()
        for _, node in next, nodes do
            set_effect(node, effect, nil)    
        end
    end

    return unwatch
end

return watch
