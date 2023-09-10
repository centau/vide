if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create_node = graph.create_node
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope
local add_child = graph.add_child
local track = graph.track

local function watch(effect: () -> ())
    local owner = get_scope()
    assert(owner)

    local node = create_node(false)
    node.effect = effect

    add_child(owner, node)

    open_scope(node)

    effect()

    close_scope()
end

return watch
