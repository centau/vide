if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local refs = graph.refs

local function untrack<T>(source: () -> T): T
    local initial = #refs

    local value = source()

    -- remove any references made since `untrack()` was called
    for i = initial, #refs do
        refs[i] = nil
    end

    return value
end

return untrack
