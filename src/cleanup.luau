if not game then script = require "test/relative-string" end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
local get_scope = graph.get_scope
local add_cleanup = graph.add_cleanup

local function cleanup(fn: () -> ())
    local node = get_scope()
    if node == nil then throw("cannot call cleanup() in a non-reactive scope") end
    add_cleanup(node, fn)
end

return cleanup

