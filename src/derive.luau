if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create_node = graph.create_node
local capture_parents = graph.capture_parents
local add_child = graph.add_child
local update = graph.update
local track = graph.track
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope

local function derive<T>(fn: () -> T): () -> T
    assert(get_scope())

    local node = create_node((false :: any) :: T)
    node.effect = function()
        node.cache = fn()
        update(node)
    end

    open_scope(node.scope)

    node.cache = capture_parents(node, fn)

    close_scope()

    return function()
        track(node)
        return node.cache
    end
end

return derive
