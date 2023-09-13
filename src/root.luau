if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local open_scope = graph.open_scope
local close_scope = graph.close_scope
local destroy = graph.destroy

local refs = {}

local function root<T>(fn: () -> T): (T, () -> ())
    local node = create_node(false, false)

    open_scope(node)

    local ok, result = pcall(fn)

    close_scope()

    if not ok then
        throw(`mount error\n{result}`)
    end

    refs[node] = true -- prevent gc of root node

    return result, function()
        refs[node] = nil
        destroy(node)
    end
end

return root
