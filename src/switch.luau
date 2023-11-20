if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
type StartNode<T> = graph.StartNode<T>
local create_node = graph.create_node
local evaluate_node = graph.evaluate_node
local set_owner = graph.set_owner
local track = graph.track
local destroy = graph.destroy
local assert_owning_scope = graph.assert_owning_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope

type Map<K, V> = { [K]: V }

local function switch<T, U>(source: () -> T): (map: Map<T, ((() -> U)?)>) -> () -> U?
    local owner = assert_owning_scope()

    return function(map)
        local last_scope: Node<false>?
        local last_component: (() -> U)?

        local function update(cached): U?
            local component = map[source()]
            if component == last_component then return cached end
            last_component = component

            if last_scope then
                destroy(last_scope :: Node<any>)
                last_scope = nil
            end

            if component == nil then return nil end

            if type(component) ~= "function" then
                throw "map must map a value to a function"
            end

            local new_scope = create_node(false, false)
            last_scope = new_scope :: Node<any>
            
            set_owner(new_scope, owner)
            open_scope(new_scope)
        
            local ok, result = pcall(component)

            close_scope()

            if not ok then error(result, 0) end

            return result
        end

        local node = create_node(nil :: U?, update)

        set_owner(node, owner)
        evaluate_node(node)

        return function()
            track(node)
            return node.cache
        end
    end
end

return switch
