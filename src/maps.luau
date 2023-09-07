if not game then script = require "test/relative-string" end

-- todo: more testing needed regarding `cleanup()` usage

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)
local graph = require(script.Parent.graph)
type Scope = graph.Scope
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local create_scope = graph.create_scope
local track = graph.track
local update = graph.update
local capture = graph.capture
local capture_parents = graph.capture_parents
local add_child = graph.add_child
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope
local destroy = graph.destroy

type Map<K, V> = { [K]: V }

local function check_primitives(t: {})
    if not flags.strict then return end

    for _, v in next, t do
        if type(v) == "table" or type(v) == "userdata" then continue end
        throw("table source map cannot return primitives")
    end
end

-- todo: optimize output array
local function indexes<K, VI, VO>(input: () -> Map<K, VI>, transform: (() -> VI, K) -> VO): () -> { VO }
    assert(get_scope())

    local root = create_scope()

    local input_cache = {} :: Map<K, VI>
    local output_cache = {} :: Map<K, VO>
    local input_nodes = {} :: Map<K, Node<VI>>
    local remove_queue = {} :: { K }
    local output_array = {} :: { VO }

    local scopes = {} :: Map<K, Scope>

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

        open_scope(root)

        -- process new or changed values
        for i, v in next, data do
            local cv = input_cache[i]

            if cv ~= v then
                if cv == nil then
                    local scope = create_scope()
                    scopes[i] = scope

                    open_scope(scope)

                    local node = create_node(v)
                    input_nodes[i] = node
                    input_cache[i] = v
                    output_cache[i] = transform(function()
                        track(node)
                        return node.cache
                    end, i)

                    close_scope()
                else
                    input_nodes[i].cache = v
                    update(input_nodes[i])
                    input_cache[i] = v
                end
            end
        end

        close_scope()

        -- output elements
        table.clear(output_array)
        for _, v in next, output_cache do
            table.insert(output_array, v)
        end
        check_primitives(output_array)
        
        return output_array
    end

    local output = create_node(false :: any)
    output.effect = function()
        update_children(input())
    end

    local value = capture_parents(output, input)

    output.cache = update_children(value)

    return function()
        track(output)
        return output.cache
    end
end

-- todo: optimize output array
local function values<K, VI, VO>(input: () -> Map<K, VI>, transform: (VI, () -> K) -> VO): () -> { VO }
    assert(get_scope())

    local root = create_scope()
    
    local cur_input_cache_up = {} :: Map<VI, K>
    local new_input_cache_up = {} :: Map<VI, K>

    local output_cache = {} :: Map<VI, VO>
    local input_nodes = {} :: Map<VI, Node<K>>
    local output_array = {} :: { VO }

    local scopes = {} :: Map<VI, Scope>

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

        open_scope(root)
    
        -- process data
        for i, v in next, data do
            new_input_cache[v] = i

            local cv = cur_input_cache[v]
            
            if cv == nil then
                local scope = create_scope()
                scopes[v] = scope

                open_scope(scope)

                local node = create_node(i)
                input_nodes[v] = node
                output_cache[v] = transform(v, function()
                    track(node)
                    return node.cache
                end)

                close_scope()
            else
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

        -- output elements
        table.clear(output_array)

        for _, v in next, output_cache do
            table.insert(output_array, v)
        end

        check_primitives(output_array)

        return output_array
    end

    local output = create_node(false :: any)
    output.effect = function()
        update_children(input())
    end

    local value = capture_parents(output, input)

    output.cache = update_children(value)

    return function()
        track(output)
        return output.cache
    end
end

return function() return indexes, values end
