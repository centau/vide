if not game then script = require "test/relative-string" end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)
local on_gc = require(script.Parent.on_gc)()
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local open_scope = graph.open_scope
local close_scope = graph.close_scope
local get_scope = graph.get_scope
local destroy = graph.destroy

local function root<T>(fn: () -> T): (T, () -> ())
    --assert(not get_scope())
    local node = create_node(false)

    open_scope(node)

    local v = fn()

    close_scope()

    return v, function()
        destroy(node)
    end
end

return root
