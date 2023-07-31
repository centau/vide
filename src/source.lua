------------------------------------------------------------------------------------------
-- vide/wrap.lua
------------------------------------------------------------------------------------------

if not game then script = require "test/wrap-require" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create = graph.create
local get = graph.get
local set = graph.set


type State<T> = (() -> T) & ((T) -> T)

local function source<T>(value: T | () -> T): State<T>
    if type(value) == "function" then value = value() end

    local node = create(value :: T)

    return function(...): T
        if select("#", ...) == 0 then return get(node) end

        local v = ... :: T
        if node.cache == v and type(v) ~= "table" then return v end

        set(node, v)
        return v
    end
end

return source
