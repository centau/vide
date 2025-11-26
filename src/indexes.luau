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
    component: (Source<V>, K, Source<boolean>) -> (Obj, ...number)
): Source<Array<Obj>>
    local update_count = 0
    local scopes = {} :: Map<K, {
        destroy: () -> (),
        object: Obj,
        value: V?,
        value_source: (V?) -> V,
        count: number,
        delay: number,
        present: (boolean?) -> boolean,
        timeout: { cancel: boolean }?,
    }>

    local output = source({} :: Array<Obj>)
    local function update_output()
        local objects = table.create(4)

        for _, scope in scopes do
            table.insert(objects, scope.object)
        end

        output(objects)
    end

    effect(function()
        local data = input()

        local count = update_count
        update_count += 1

        local children_need_update = false -- set to true if a scope is created or destroyed

        -- create or update scopes
        for i, v in data do
            local scope = scopes[i]

            if scope == nil then -- create new scope and create component
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

                scopes[i] = {
                    destroy = destroy,
                    object = object,
                    value = v,
                    value_source = value_source,
                    count = count,
                    delay = delay or 0,
                    present = present,
                    timeout = nil,
                }
            else -- update scope
                scope.count = count

                if scope.value ~= v then
                    if scope.timeout then -- index is in input table again; cancel destruction
                        scope.timeout.cancel = true
                        scope.timeout = nil
                        scope.present(true)
                    end
                    
                    scope.value = v
                    scope.value_source(v)
                end
            end
        end

        -- destroy scopes
        for i, scope in scopes do
            if scope.count < count then -- if count is not latest then index is no longer in the input table
                scope.present(false)

                if scope.delay == 0 then
                    scope.destroy()
                    scopes[i] = nil
                    children_need_update = true
                else
                    scope.value = nil -- set to nil for the `scope.value ~= v` check
                    if scope.timeout == nil then
                        scope.timeout = timeout(scope.delay, function() -- todo: possible redundant updates
                            scope.destroy()
                            scopes[i] = nil
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
