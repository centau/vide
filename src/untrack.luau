if not game then script = require "test/relative-string" end

local create = require(script.Parent.create)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope

local function untrack<T>(source: () -> T): T
    local scope = get_scope()
    assert(scope)

    local effect = scope.effect
    scope.effect = false

    local v = source()

    scope.effect = effect :: () -> ()

    return v
end

return untrack
