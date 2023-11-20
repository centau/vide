if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create_node = graph.create_node
local set_owner = graph.set_owner
local track = graph.track
local assert_owning_scope = graph.assert_owning_scope
local evaluate_node = graph.evaluate_node

local function derive<T>(source: () -> T): () -> T
    local owner = assert_owning_scope()

    local node = create_node(false :: any, source)

    set_owner(node, owner)
    evaluate_node(node)

    return function()
        track(node)
        return node.cache
    end
end

return derive
