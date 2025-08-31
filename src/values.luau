local flags = require "./flags"
local branch = require "./branch"
local source = require "./source"
local effect = require "./effect"
local timeout = require "./timeout" ()

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type Source<T> = () -> T

local function values<K, V, Obj>(
    input: Source<Map<K, V>>,
    component: (V, Source<K>, Source<boolean>) -> (Obj, number?)
): Source<Array<Obj>>
    local update_count = 0
    local caches = {} :: Map<V, {
        destroy_scope: () -> (),
        present: (boolean?) -> boolean,
        index: K?,
        index_source: (K?) -> K,
        object: Obj,
        delay: number,
        timeout: { cancel: boolean }?,
        count: number,
    }>

    local output = source({} :: Array<Obj>)
    local function update_output()
        local array = table.create(16)
        for _, cache in caches do
            table.insert(array, cache.object)
        end
        output(array)
    end

    effect(function()
        local data = input()

        local count = update_count
        update_count += 1

        local children_need_update = false -- set to true if a scope is created or destroyed

        if flags.strict then
            local map = {}
            for _, v in data do
                if map[v] then
                    error("table source passed to `values()` contains duplicate values", 0)
                end
                map[v] = true
            end
        end

        -- process data
        for i, v in data do
            local cache = caches[v]

            if cache == nil then -- create new scope and create component
                local index_source = source(i)
                local present = source(false)

                local delay = nil :: number?
                local destroy, object = branch(function()
                    local object, t = component(v, index_source, present)
                    delay = t
                    return object
                end)

                present(true)
                
                children_need_update = true

                caches[v] = {
                    count = count,
                    index = i,
                    destroy_scope = destroy,
                    index_source = index_source,
                    present = present,
                    delay = delay or 0,
                    object = object
                }
            else -- update source
                cache.count = count

                if cache.index ~= i then
                    if cache.timeout then
                        cache.timeout.cancel = true
                        cache.timeout = nil
                        cache.present(true)
                    end
                    
                    cache.index = i
                    cache.index_source(i)
                end
            end
        end

        -- remove old values
        for v, cache in caches do
            if cache.count < count then -- if count is not latest then value is no longer in the input table
                cache.present(false)

                if cache.delay == 0 then
                    cache.destroy_scope()
                    caches[v] = nil
                    children_need_update = true
                else
                    cache.index = nil
                    if cache.timeout == nil then
                        cache.timeout = timeout(cache.delay, function() -- todo: avoid redundant updates (e.g. values() input is cleared)
                            cache.destroy_scope()
                            caches[v] = nil
                            update_output()
                        end)
                    end
                end
            end
        end

        if children_need_update then
            update_output()
        end
    end)

    return output
end

return values
