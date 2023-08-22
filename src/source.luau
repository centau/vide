if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create = graph.create
local set = graph.set

export type Source<T> = (() -> T) & ((T) -> T)

local function source<T>(value: T): Source<T>
    local node, read_node_value = create(value :: T)

    return function(...): T
        if select("#", ...) == 0 then return read_node_value() end -- check if any args were given

        local v = ... :: T
        if node.cache == v and (type(v) ~= "table" or table.isfrozen(v)) then return v end

        set(node, v)
        return v
    end
end

return source :: (<T>(value: T) -> Source<T>) & (<T>() -> Source<T>)
