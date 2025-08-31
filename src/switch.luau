local branch = require "./branch"
local source = require "./source"
local effect = require "./effect"
local timeout = require "./timeout" ()

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type Source<T> = () -> T
type Component<T> = (Source<boolean>) -> T

local function switch_map<K, Obj>(
    input: Source<K>,
    map: Map<K, Component<Obj>>
): Source<nil | Obj | Array<Obj>>
    local output = source(nil :: nil | Obj | Array<Obj>)

    local caches = {} :: Map<K, {
        destroy_scope: () -> (),
        present: (boolean?) -> boolean,
        object: Obj,
        delay: number,
        timeout: { cancel: boolean }?
    }>

    local function update_output()
        local objects = {}
        for _, cache in caches do
            table.insert(objects, cache.object)
        end

        output(
            if objects[2] then objects
            elseif objects[1] then objects[1]
            else nil
        )
    end

    effect(function()
        local key: K? = input()

        for k, cache in caches do
            if k == key then continue end
            cache.present(false)

            if cache.delay == 0 then
                cache.destroy_scope()
                caches[k] = nil
            else
                if cache.timeout == nil then
                    cache.timeout = timeout(cache.delay, function()
                        cache.destroy_scope()
                        caches[k] = nil
                        update_output()
                    end)
                end
            end
        end

        if key ~= nil then
            local cache = caches[key]

            if cache then
                cache.present(true)

                if cache.timeout then
                    cache.timeout.cancel = true
                    cache.timeout = nil
                end
            else
                local component = map[key]

                if component ~= nil then
                    if type(component) ~= "function" then
                        error("map must map a value to a function", 0)
                    end

                    local present = source(false)

                    local delay = nil :: number?
                    local destroy, object = branch(function()
                        local object, t = component(present)
                        delay = t
                        return object
                    end)

                    present(true)

                    caches[key] = {
                        destroy_scope = destroy,
                        present = present,
                        object = object,
                        delay = delay or 0,
                        timeout = nil
                    }
                end
            end
        end

        update_output()
    end)

    return output
end

local function switch<K, Obj>(input: Source<K>): (map: Map<K, Component<Obj>>) -> Source<nil | Obj | Array<Obj>>
    return function(map)
        return switch_map(input, map)
    end
end

return switch
