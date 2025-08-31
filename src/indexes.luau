local flags = require "./flags"
local branch = require "./branch"
local source = require "./source"
local effect = require "./effect"
local timeout = require "./timeout" ()

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type Source<T> = () -> T

local function indexes<K, V, Obj>(
    input: Source<Map<K, V>>,
    component: (Source<V>, K, Source<boolean>) -> (Obj, number?)
): Source<Array<Obj>>
    local update_count = 0
    local caches = {} :: Map<K, {
        destroy_scope: () -> (),
        present: (boolean?) -> boolean,
        value: V?,
        value_source: (V?) -> V,
        object: Obj,
        delay: number,
        timeout: { cancel: boolean }?,
        count: number,
    }>

    local output = source({} :: Array<Obj>)
    local function update_output()
        local array = table.create(#caches)
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

        -- process data
        for i, v in data do
            local cache = caches[i]

            if cache == nil then -- create new scope and create component
                local value_source = source(v)
                local present = source(false)

                local delay = nil :: number?
                local destroy, object = branch(function()
                    local object, t = component(value_source, i, present)
                    delay = t
                    return object
                end)

                present(true)
                
                children_need_update = true

                caches[i] = {
                    count = count,
                    value = v,
                    destroy_scope = destroy,
                    value_source = value_source,
                    present = present,
                    delay = delay or 0,
                    object = object
                }
            else -- update source
                cache.count = count

                if cache.value ~= v then
                    if cache.timeout then
                        cache.timeout.cancel = true
                        cache.timeout = nil
                        cache.present(true)
                    end
                    
                    cache.value = v
                    cache.value_source(v)
                end
            end
        end

        -- remove old indexes
        for i, cache in caches do
            if cache.count < count then -- if count is not latest then value is no longer in the input table
                cache.present(false)

                if cache.delay == 0 then
                    cache.destroy_scope()
                    caches[i] = nil
                    children_need_update = true
                else
                    cache.value = nil
                    if cache.timeout == nil then
                        cache.timeout = timeout(cache.delay, function() -- todo: avoid redundant updates (e.g. indexes() input is cleared)
                            cache.destroy_scope()
                            caches[i] = nil
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

return indexes
