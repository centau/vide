if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
local create_node = graph.create_node
local get_scope = graph.get_scope
local evaluate_node = graph.evaluate_node
local set_owner = graph.set_owner

local function effect<T>(effect: (T) -> T, initial_value: T)
    local owner = get_scope()
    if not owner then
        throw("cannot create effect in non-reactive scope")
    end; assert(owner)

    local node = create_node(initial_value, effect)
    set_owner(node, owner)
    evaluate_node(node)
end

return effect :: (<T>(effect: (T) -> T, initial_value: T) -> ()) & ((effect: () -> ()) -> ())
