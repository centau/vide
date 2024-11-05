if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>

export type Source<T> = (() -> T) & ((value: T) -> T)

local function parent<T>(fn: () -> T): T
    local node = graph.get_scope()
    if not node then error("") end

    local parent_node = node.owner
    if not parent_node then error("") end

    graph.push_scope(parent_node :: Node<unknown>)

    local ok, result = pcall(fn)

    graph.pop_scope()

    if not ok then error(result, 0) end

    return result
end

return parent
