if not game then script = require "test/relative-string" end

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
local assert_owning_scope = graph.assert_owning_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope
local evaluate_node = graph.evaluate_node
local destroy = graph.destroy

type Map<K, V> = { [K]: V }

local function check_primitives(t: {})
    if not flags.strict then return end

    for _, v in next, t do
        if type(v) == "table" or type(v) == "userdata" then continue end
        throw("table source map cannot return primitives")
    end
end

local function indexes<K, VI, VO>(input: () -> Map<K, VI>, transform: (() -> VI, K) -> VO): () -> { VO }
    local owner = assert_owning_scope()

    local subowner = create_node(false, false)
    set_owner(subowner, owner)

    local input_cache = {} :: Map<K, VI>
    local output_cache = {} :: Map<K, VO>
    local input_nodes = {} :: Map<K, StartNode<VI>>
    local remove_queue = {} :: { K }
    local scopes = {} :: Map<K, Node<unknown>>

    local function update_children(data)
        -- queue removed values
        for i in next, input_cache do
            if data[i] == nil then
                table.insert(remove_queue, i)
            end
        end

        -- remove queued values
        for _, i in next, remove_queue do
            destroy(scopes[i])

            input_cache[i] = nil
            output_cache[i] = nil
            input_nodes[i] = nil
            scopes[i] = nil
        end

        table.clear(remove_queue)

        open_scope(subowner)

        -- process new or changed values
        for i, v in next, data do
            local cv = input_cache[i]

            if cv ~= v then
                if cv == nil then -- create new scope and run transform
                    local scope = create_node(false, false)
                    scopes[i] = scope :: Node<any>

                    local node = create_start_node(v)

                    set_owner(scope, subowner)
                    open_scope(scope)

                    local ok, result = pcall(transform, function()
                        track(node)
                        return node.cache
                    end, i)
                    
                    close_scope()

                    if not ok then
                        close_scope() -- subowner scope
                        error(result, 0)
                    end
                    
                    input_nodes[i] = node
                    output_cache[i] = result
                else -- update source
                    input_nodes[i].cache = v
                    update(input_nodes[i])
                end

                input_cache[i] = v
            end
        end

        close_scope()

        local output_array = table.create(#scopes)
        for _, v in next, output_cache do
            table.insert(output_array, v)
        end
        check_primitives(output_array)
        
        return output_array
    end

    local node = create_node(false :: any, function()
        return update_children(input())
    end)
    set_owner(node, owner)

    evaluate_node(node)

    return function()
        track(node)
        return node.cache
    end
end

local function values<K, VI, VO>(input: () -> Map<K, VI>, transform: (VI, () -> K) -> VO): () -> { VO }
    local owner = assert_owning_scope()

    local subowner = create_node(false, false)
    set_owner(subowner, owner)
    
    local cur_input_cache_up = {} :: Map<VI, K>
    local new_input_cache_up = {} :: Map<VI, K>
    local output_cache = {} :: Map<VI, VO>
    local input_nodes = {} :: Map<VI, StartNode<K>>
    local scopes = {} :: Map<VI, Node<unknown>>

    local function update_children(data: Map<K, VI>)
        local cur_input_cache, new_input_cache = cur_input_cache_up, new_input_cache_up

        if flags.strict then
            local cache = {}
            for _, v in next, data do
                if cache[v] ~= nil then
                    throw "duplicate table value detected"
                end
                cache[v] = true
            end
        end

        open_scope(subowner)
    
        -- process data
        for i, v in next, data do
            new_input_cache[v] = i

            local cv = cur_input_cache[v]
            
            if cv == nil then -- create new scope and run transform
                local scope = create_node(false, false)
                scopes[v] = scope :: Node<any>

                local node = create_start_node(i)
    
                set_owner(scope, subowner)
                open_scope(scope)
                
                local ok, result = pcall(transform, v, function()
                    track(node)
                    return node.cache
                end)
                
                close_scope()

                if not ok then
                    close_scope() -- subowner scope
                    error(result, 0)
                end

                input_nodes[v] = node
                output_cache[v] = result
            else -- update source
                if cv ~= i then
                    input_nodes[v].cache = i
                    update(input_nodes[v])
                end

                cur_input_cache[v] = nil
            end
        end

        close_scope()

        -- remove old values
        for v in next, cur_input_cache do
            destroy(scopes[v])

            output_cache[v] = nil
            input_nodes[v] = nil
            scopes[v] = nil
        end

        -- update buffer cache
        table.clear(cur_input_cache)
        cur_input_cache_up, new_input_cache_up = new_input_cache, cur_input_cache

        local output_array = table.create(#scopes)
        for _, v in next, output_cache do
            table.insert(output_array, v)
        end
        check_primitives(output_array)

        return output_array
    end

    local node = create_node(false :: any, function()
        return update_children(input())
    end)
    set_owner(node, owner)

    evaluate_node(node)

    return function()
        track(node)
        return node.cache
    end
end

return function() return indexes, values end
