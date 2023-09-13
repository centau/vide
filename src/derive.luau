if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
local create_node = graph.create_node
local set_owner = graph.set_owner
local track = graph.track
local get_scope = graph.get_scope
local evaluate_node = graph.evaluate_node

local function derive<T>(fn: () -> T): () -> T
    local owner = get_scope()
    if not owner then throw("cannot derive in non-reactive scope") end
    assert(owner)

    local node = create_node(false :: any, fn)

    set_owner(node, owner)
    evaluate_node(node)

    return function()
        track(node)
        return node.cache
    end
end

return derive
