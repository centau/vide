local graph = require "./graph"
local create_node = graph.create_node
local push_scope_as_child_of = graph.push_scope_as_child_of
local assert_stable_scope = graph.assert_stable_scope
local evaluate_node = graph.evaluate_node

local function derive<T>(source: () -> T): () -> T
    local node = create_node(assert_stable_scope(), source, false :: any)

    evaluate_node(node)

    return function()
        push_scope_as_child_of(node)
        return node.cache
    end
end

return derive
