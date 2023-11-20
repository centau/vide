if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create_start_node = graph.create_start_node
local track = graph.track
local update = graph.update

export type Source<T> = (() -> T) & ((value: T) -> T)

local function source<T>(initial_value: T): Source<T>
    local node = create_start_node(initial_value)

    return function(...): T
        if select("#", ...) == 0 then -- no args were given
            track(node)
            return node.cache
        end

        local v = ... :: T
        if node.cache == v and (type(v) ~= "table" or table.isfrozen(v)) then 
            return v
        end

        node.cache = v
        update(node)
        return v
    end
end

return source :: (<T>(initial_value: T) -> Source<T>) & (<T>() -> Source<T>)
