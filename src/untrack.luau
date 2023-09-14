if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local get_scope = graph.get_scope

local function untrack<T>(source: () -> T): T
    local scope = get_scope()
    if not scope then
        throw("cannot untrack in non-reactive scope")
    end; assert(scope)

    -- sources are only tracked if the node in scope has an effect
    local effect = scope.effect
    scope.effect = false

    local ok, result = pcall(source)

    scope.effect = effect :: () -> ()

    if not ok then error(result, 0) end

    return result
end

return untrack
