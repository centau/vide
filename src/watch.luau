if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create_node = graph.create_node
local capture_parents = graph.capture_parents
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope

local function watch(effect: () -> ())
    assert(get_scope())

    local node = create_node(false)
    node.effect = effect

    open_scope(node.scope)

    capture_parents(node, effect :: () -> any)

    close_scope()
end

return watch
