if not game then script = require "test/relative-string" end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)
local on_gc = require(script.Parent.on_gc)()
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create = graph.create
local init_scope = graph.init_scope
local close_scope = graph.close_scope
local get_scope = graph.get_scope
local destroy = graph.destroy

local refs = {} :: { [Node<unknown>]: unknown }
setmetatable(refs :: any, { __mode = "v" })

local function root<T>(fn: () -> T): T
    assert(not get_scope())

    local node = create(nil) -- todo: lifetime with return vaue from fn

    init_scope(node)

    local v = fn()

    close_scope()

    refs[node] = v

    on_gc(v, function()
        destroy(node)
    end)

    return v
end

return root
