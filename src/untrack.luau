if not game then script = require "test/relative-string" end

local create = require(script.Parent.create)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local get_stack_scope = graph.get_stack_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope

local non_tracking_scope = create_node(false)

local function untrack<T>(source: () -> T): T
    local scope = get_stack_scope(1)

    open_scope(scope or non_tracking_scope)

    local v = source()

    close_scope()

    return v
end

return untrack
