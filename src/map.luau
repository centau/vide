if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create = graph.create
local set = graph.set
local capture = graph.capture
local link = graph.link

type Map<K, V> = { [K]: V }

local function map<K, VI, VO>(input: () -> Map<K, VI>, transform: (() -> VI, K) -> VO): () -> Map<K, VO>
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

        return output_cache
    end

    local function derive()
        return recompute(input())
    end

    local output, output_get = create(output_cache)

    local nodes, value = capture(input)

    for _, node in next, nodes do
        link(node, output, derive)
    end

    output.cache = recompute(value)

    return output_get
end

return map
