if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create = graph.create
local add_parent = graph.add_parent
local add_child = graph.add_child
local capture = graph.capture
local init_scope = graph.init_scope
local close_scope = graph.close_scope
local destroy = graph.destroy

local function watch(effect: () -> ()): () -> ()
    local node = create(false)

    init_scope(node)

    local nodes = capture(effect :: () -> nil)

    close_scope()

    node.effect = effect

    for _, parent in next, nodes do
        add_parent(node, parent)
        add_child(parent, node)
    end


    local function unwatch()
        destroy(node)
    end

    return unwatch
end

return watch
