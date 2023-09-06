if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create = graph.create
local capture = graph.capture
local add_child = graph.add_child
local set_effect = graph.set_effect
local update = graph.update
local track = graph.track
local init_scope = graph.init_scope
local close_scope = graph.close_scope

local function derive<T>(fn: () -> T): () -> T
    local node = create((false :: any) :: T)

    init_scope(node)

    local nodes, value = capture(fn)

    close_scope()

    for _, parent in next, nodes do
        add_child(parent, node)
    end

    set_effect(node, function()
        node.cache = fn()
        update(node)
    end)

    node.cache = value

    return function()
        track(node)
        return node.cache
    end
end

return derive
