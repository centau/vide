if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
local create_node = graph.create_node
local set_owner = graph.set_owner
local track = graph.track
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope


local function derive<T>(fn: () -> T): () -> T
    local owner = get_scope()
    if not owner then throw("cannot derive in non-reactive scope") end
    assert(owner)

    local node = create_node((false :: any) :: T)
    node.effect = function()
        return fn()
    end

    set_owner(node, owner)
    open_scope(node)

    node.cache = fn()

    close_scope()

    return function()
        track(node)
        return node.cache
    end
end

return derive
