if not game then script = require "test/wrap-require" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create = graph.create
local get = graph.get
local set = graph.set


type Source<T> = (() -> T) & ((T) -> T)

local function source<T>(value: T): Source<T>
    local node, get_value = create(value :: T)

    return function(...): T
        if select("#", ...) == 0 then return get_value() end

        local v = ... :: T
        if node.cache == v and type(v) ~= "table" then return v end

        set(node, v)
        return v
    end
end

return source :: (<T>(value: T) -> Source<T>) & (<T>() -> Source<T>)
