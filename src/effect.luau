if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create_node = graph.create_node
local assert_owning_scope = graph.assert_owning_scope
local evaluate_node = graph.evaluate_node
local set_owner = graph.set_owner

local function effect<T>(callback: (T) -> T, initial_value: T)
    local owner = assert_owning_scope()

    local node = create_node(initial_value, callback)

    set_owner(node, owner)
    evaluate_node(node)
end

return effect :: (<T>(callback: (T) -> T, initial_value: T) -> ()) & ((callback: () -> ()) -> ())
