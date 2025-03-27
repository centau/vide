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

local function check_primitives(t: {})
    if not flags.strict then return end

    for _, v in t do
        if type(v) == "table" or type(v) == "userdata" or type(v) == "function" then continue end
        error("table source map cannot return primitives", 0)
    end
end

local function values<K, VI, VO>(input: () -> Map<K, VI>, transform: (VI, () -> K) -> VO, delay: number?): () -> { VO }
    local owner  = assert_stable_scope()
    local subowner = create_node(owner, false, false)
    
    local update_count = 0

    local caches = {} :: Map<VI, {
        count: number,
        index: K,
        scope: Node<unknown>,
        index_source: SourceNode<K>,
        alive_source: SourceNode<boolean>,
        result: VO,
    }>

    local function update_children(data: Map<K, VI>)
        local count = update_count
        update_count += 1

        local children_need_update = false

        if flags.strict then
            local cache = {}
            for _, v in data do
                if cache[v] ~= nil then
                    error "duplicate table value detected"
                end
                cache[v] = true
            end
        end

        push_scope(subowner)
    
        -- process data
        for i, v in data do
            local cache = caches[v]

            if cache == nil then -- create new scope and run transform
                local scope = create_node(subowner, false, false)
                local index_source = create_source_node(i)

                local new_cache = {
                    count = count,
                    index = i,
                    scope = scope :: Node<unknown>,
                    index_source = index_source :: SourceNode<K>,
                    alive_source = nil :: any,
                    result = false :: any,
                }
                -- must be set before transform is run so that the scope can
                -- be destroyed if the transform itself updates the input
                -- which lets the strict active scope destruction check work
                caches[v] = new_cache
    
                push_scope(scope)
                
                local ok, result = xpcall(transform, debug.traceback, v, function()
                    push_scope_as_child_of(index_source)
                    return index_source.cache
                end)
                
                pop_scope()

                if not ok then
                    pop_scope() -- subowner scope
                    error(result, 0)
                end

                new_cache.result = result
                children_need_update = true
            else -- update source
                cache.count = count

                if cache.index ~= i then
                    cache.index = i
                    cache.index_source.cache = i
                    update_descendants(cache.index_source)
                end
            end
        end

        pop_scope()

        -- remove old values
        for v, cache in caches do
            if cache.count < count then
                destroy(cache.scope)
                caches[v] = nil
                children_need_update = true
            end
        end

        if children_need_update then
            local output_array = table.create(#data)
            for _, cache in caches do
                table.insert(output_array, cache.result)
            end
            check_primitives(output_array)

            return output_array
        else
            return nil
        end
    end

    local node = create_node(owner, function(pre_children) -- todo: add test
        return update_children(input()) or pre_children
    end, {})

    evaluate_node(node)

    return function()
        push_scope_as_child_of(node)
        return node.cache
    end
end

return values
