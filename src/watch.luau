if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create_node = graph.create_node
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope
local set_owner = graph.set_owner

local function watch<T>(effect: (T) -> T, initial_value: T)
    local owner = get_scope()
    assert(owner)

    local node = create_node(false)
    node.effect = effect

    set_owner(node, owner)
    open_scope(node)

    effect(initial_value)

    close_scope()
end

return watch :: (<T>(effect: (T) -> T, initial_value: T) -> ()) & ((effect: () -> ()) -> ())
