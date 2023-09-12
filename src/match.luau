local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
type StartNode<T> = graph.StartNode<T>
local create_node = graph.create_node
local create_start_node = graph.create_start_node
local set_owner = graph.set_owner
local track = graph.track
local update = graph.update
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope
local destroy = graph.destroy

type Map<K, V> = { [K]: V }

local function match<T, U>(source: () -> T, map: Map<T, () -> U>): () -> U
    local owner = get_scope()
    assert(owner)

    local match_updater = create_node(nil)
    function match_updater.effect()
        local value = source()
        open_scope(owner)
        local component = map[value]()
        close_scope()
        output.cache = component
    end

    local output = create_start_node()
end
