if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create = graph.create
local set = graph.set
local capture = graph.capture
local link = graph.link

type Map<K, V> = { [K]: V }

-- todo: optimize, double buffering?

local function indexes<K, VI, VO>(input: () -> Map<K, VI>, transform: (() -> VI, K) -> VO): () -> { VO }
    local input_cache = {} :: Map<K, VI>
    local output_cache = {} :: Map<K, VO>
    local input_nodes = {} :: Map<K, Node<VI>>
    local remove_queue = {} :: { K }

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

        -- process new or changed values
        for k, v in next, data do
            if input_cache[k] == nil then
                local node, get_value = create(v)
                input_nodes[k] = node
                output_cache[k] = transform(get_value, k)
            elseif input_cache[k] ~= v then
                set(input_nodes[k], v)
            end
            input_cache[k] = v
        end

        local output = {}

        for _, v in next, output_cache do
            table.insert(output, v)
        end

        return output
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

local function values<K, VI, VO>(input: () -> Map<K, VI>, transform: (VI, () -> K) -> VO): () -> { VO }
    local input_cache = {} :: Map<VI, K>
    local output_cache = {} :: Map<VI, VO>
    local input_nodes = {} :: Map<VI, Node<K>>
    local remove_queue = {} :: { VI }

    local function recompute(data: Map<K, VI>)
        local inverted_data = {}

        -- process new or changed values
        for i, v in next, data do
            if input_cache[v] == nil then
                local node, get_value = create(i)
                input_nodes[v] = node
                input_cache[v] = i
                output_cache[v] = transform(v, get_value)
            elseif input_cache[v] ~= i then
                set(input_nodes[v], i)
            end
            
            inverted_data[v] = i
        end

        -- queue removed values
        for v, k in next, input_cache do
            if inverted_data[v] == nil then
                table.insert(remove_queue, v)
            end
        end

        -- remove queued values
        for _, k in next, remove_queue do
            input_cache[k] = nil
            output_cache[k] = nil
            input_nodes[k] = nil
        end

        local output = {}

        for _, v in next, output_cache do
            table.insert(output, v)
        end

        return output
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

return function() return indexes, values end
