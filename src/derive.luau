if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create = graph.create
local capture_and_link = graph.capture_and_link

local function derive<T>(fn: () -> T): () -> T
    local node, read_node_value = create((false :: any) :: T)

    node.cache = capture_and_link(node, fn)

    return read_node_value
end

return derive
