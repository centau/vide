if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create = graph.create
local set_child = graph.set_child
local capture = graph.capture
local create_and_open_scope = graph.create_and_open_scope
local close_scope = graph.close_scope

local ref = {}

local function watch(effect: () -> ()): () -> ()
    local node = create(nil)

    create_and_open_scope(node)

    local nodes = capture(effect :: () -> nil)

    close_scope()

    node.effect = effect

    -- register effect with permanent lifetime
    for _, parent in next, nodes do
        set_child(parent, node)  
    end

    ref[node] = true -- prevent gc of node

    local function unwatch()
        -- unregister effect from all nodes
        node.effect = function() end
        ref[node] = nil
    end

    return unwatch
end

return watch
