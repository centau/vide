if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local get_scope = graph.get_scope

local function untrack<T>(source: () -> T): T
    local scope = get_scope()
    if not scope then throw("cannot untrack  in non-reactive scope") end
    assert(scope)

    local effect = scope.effect
    scope.effect = false

    local v = source()

    scope.effect = effect :: () -> ()

    return v
end

return untrack
