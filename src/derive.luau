if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create = graph.create
local capture_and_link = graph.capture_and_link
local create_and_open_scope = graph.create_and_open_scope
local close_scope = graph.close_scope

local function derive<T>(fn: () -> T): () -> T
    local node, read_node_value = create((false :: any) :: T)

    create_and_open_scope(node)

    node.cache = capture_and_link(node, fn)

    close_scope()

    return read_node_value
end

return derive
