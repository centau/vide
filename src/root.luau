if not game then script = require "test/relative-string" end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
local create = graph.create
local create_and_open_scope = graph.create_and_open_scope
local close_scope = graph.close_scope
local get_scope = graph.get_scope
local add_cleanup = graph.add_cleanup

local function root<T>(fn: () -> T): T
    local node = create(nil) -- todo: lifetime with return vaue from fn

    create_and_open_scope(node)

    local v = fn()

    close_scope()

    return v
end

return root
