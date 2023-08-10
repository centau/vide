if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create = graph.create
local set = graph.set
local capture = graph.capture
local link = graph.link

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
    local input_cache = {} :: Map<K, VI>
    local output_cache = {} :: Map<K, VO>
    local input_nodes = {} :: Map<K, Node<VI>>
    local remove_queue = {} :: { K }
    local output_array = {} :: { VO }

    local function recompute(data)
        -- queue removed values
        for k in next, input_cache do
            if data[k] == nil then
                table.insert(remove_queue, k)
            end
        end

        -- remove queued values
        for _, k in next, remove_queue do
            input_cache[k] = nil
            output_cache[k] = nil
            input_nodes[k] = nil
        end

        table.clear(remove_queue)

        -- process new or changed values
        for k, v in next, data do
            local cv = input_cache[k]

            if cv == nil then
                local node, get_value = create(v)
                input_nodes[k] = node
                output_cache[k] = transform(get_value, k)
                input_cache[k] = v
            elseif cv ~= v then
                set(input_nodes[k], v)
                input_cache[k] = v
            end
        end

        -- output elements
        table.clear(output_array)
        for _, v in next, output_cache do
            table.insert(output_array, v)
        end
        check_primitives(output_array)
        
        return output_array
    end

    local function derive()
        return recompute(input())
    end

    local output, output_get = create(nil :: any)

    local nodes, value = capture(input)

    for _, node in next, nodes do
        link(node, output, derive)
    end

    output.cache = recompute(value)

    return output_get
end

-- todo: optimize output array
local function values<K, VI, VO>(input: () -> Map<K, VI>, transform: (VI, () -> K) -> VO): () -> { VO }
    local cur_input_cache_up = {} :: Map<VI, K>
    local new_input_cache_up = {} :: Map<VI, K>

    local output_cache = {} :: Map<VI, VO>
    local input_nodes = {} :: Map<VI, Node<K>>
    local output_array = {} :: { VO }

    local function recompute(data: Map<K, VI>)
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
    
        -- process data
        for i, v in next, data do
            new_input_cache[v] = i

            local cv = cur_input_cache[v]
            
            if cv == nil then
                local node, get_value = create(i)
                input_nodes[v] = node
                output_cache[v] = transform(v, get_value)
            else
                if cv ~= i then
                    set(input_nodes[v], i)
                end
                cur_input_cache[v] = nil
            end
        end

        -- remove old values
        for v in next, cur_input_cache do
            output_cache[v] = nil
            input_nodes[v] = nil
        end

        -- update buffer cache
        table.clear(cur_input_cache)
        cur_input_cache_up, new_input_cache_up = new_input_cache, cur_input_cache

        -- output elements
        table.clear(output_array)

        for _, v in next, output_cache do
            table.insert(output_array, v)
        end

        return output_array
    end

    local function derive()
        return recompute(input())
    end

    local output, output_get = create(nil :: any)

    local nodes, value = capture(input)

    for _, node in next, nodes do
        link(node, output, derive)
    end
    check_primitives(output_array)

    output.cache = recompute(value)

    return output_get
end

return function() return indexes, values end
