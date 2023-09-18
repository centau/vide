if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
local get_scope = graph.get_scope
local add_cleanup = graph.add_cleanup

local function cleanup(callback: () -> ())
    local scope = get_scope()

    if not scope then
        throw "cannot cleanup in a non-reactive scope"
    end; assert(scope)

    add_cleanup(scope, callback)
end

return cleanup

