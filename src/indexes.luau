local flags = require "./flags"
local graph = require "./graph"
type Node<T> = graph.Node<T>
type SourceNode<T> = graph.SourceNode<T>
local create_node = graph.create_node
local create_source_node = graph.create_source_node
local push_scope_as_child_of = graph.push_scope_as_child_of
local update_descendants = graph.update_descendants
local assert_stable_scope = graph.assert_stable_scope
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local evaluate_node = graph.evaluate_node
local destroy = graph.destroy

type Map<K, V> = { [K]: V }

local function indexes<K, VI, VO>(input: () -> Map<K, VI>, transform: (() -> VI, K) -> VO, delay: number?): () -> { VO }
    local owner = assert_stable_scope()
    local subowner = create_node(owner, false, false)

    local input_cache = {} :: Map<K, VI>
    local output_cache = {} :: Map<K, VO>
    local input_nodes = {} :: Map<K, SourceNode<VI>>
    local scopes = {} :: Map<K, Node<unknown>>

    local function update_children(data)
        local children_need_update = false

        -- remove old indexes
        for i in input_cache do
            if data[i] == nil then
                destroy(scopes[i])
                input_cache[i] = nil
                output_cache[i] = nil
                input_nodes[i] = nil
                scopes[i] = nil
                children_need_update = true
            end
        end

        push_scope(subowner)

        -- process new or changed values
        for i, v in data do
            local cv = input_cache[i]

            if cv ~= v then
                input_cache[i] = v

                if cv == nil then -- create new scope and run transform
                    local scope = create_node(subowner, false, false)
                    scopes[i] = scope :: Node<any>

                    local node = create_source_node(v)

                    push_scope(scope)

                    local ok, result = xpcall(transform, debug.traceback, function()
                        push_scope_as_child_of(node)
                        return node.cache
                    end, i)
                    
                    pop_scope()

                    if not ok then
                        pop_scope() -- subowner scope
                        error(result, 0)
                    end
                    
                    input_nodes[i] = node
                    output_cache[i] = result
                    children_need_update = true
                else -- update source
                    input_nodes[i].cache = v
                    update_descendants(input_nodes[i])
                end
            end
        end

        pop_scope()

        if children_need_update then
            local output_array_size = #output_cache
            local output_array

            -- check if the table contains a dictionary section
            if output_array_size > 0 and next(output_cache, output_array_size) == nil then
                output_array = table.clone(output_cache)
            else
                output_array = table.create(output_array_size)
                for _, v in output_cache do
                    table.insert(output_array, v)
                end
            end
            
            return output_array
        else
            return nil
        end
    end

    local node = create_node(owner, function(pre_children)
        return update_children(input()) or pre_children
    end, {})

    evaluate_node(node)

    return function()
        push_scope_as_child_of(node)
        return node.cache
    end
end

return indexes
