if not game then script = require "test/relative-string" end

local graph = require(script.Parent.graph)
local create = graph.create
local capture_and_link = graph.capture_and_link

local function derive<T>(fn: () -> T): () -> T
    local node, node_get = create((nil :: any) :: T)

    node.cache = capture_and_link(node, fn)

    return node_get
end

return derive
