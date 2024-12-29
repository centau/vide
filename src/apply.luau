local typeof = game and typeof or require "../test/mock".typeof :: never

local flags = require "./flags"
local implicit_effect = require "./implicit_effect"
local _, is_action = require "./action"()
local graph = require "./graph"
type Node<T> = graph.Node<T>

type Array<V> = { V }
type ArrayOrV<V> = {ArrayOrV<V>} | V
type Map<K, V> = { [K]: V }

type Cache = {
    -- event listeners to connect after properties are set
    events: Array<
        | string -- 1. event name
        | () -> () -- 2. listener
    >,

    -- actions to run after events are connected
    actions: Map<
        number, -- priority
        Array<(Instance) -> ()> -- action callbacks
    >,

    -- cache to detect duplicate property setting at same nesting depth
    nested_debug: Map<
        number, -- depth
        Map<string, true> -- set of property names
    >,

    -- each nested layer occupies two indexes: 1. table ref 2. nested depth
    -- e.g. { t1 = { t3 = {} }, t2 = {} } -> { t1, 1, t2, 1, t3, 2 }
    nested_stack: { {} | number }
}

local free_cache: Cache?

local function borrow_cache(): Cache
    if free_cache then
        local cache = free_cache
        free_cache = nil
        return cache
    else
        return {
            events = {},
            actions = setmetatable({} :: any, { -- lazy init
                __index = function(self, i) self[i] = {}; return self[i] end
            }),
            nested_debug = setmetatable({} :: any, {
                __index = function(self, i: number) self[i] = {}; return self[i] end
            }),
            nested_stack = {}
        }
    end
end

local function return_cache(cache: Cache )
    free_cache = cache
end

local function process_properties(properties: Map<unknown, unknown>, instance: Instance, cache: Cache, depth: number)
    for property, value in properties do
        if property == "Parent" then continue end

        if type(property) == "string" then
            if flags.strict then -- check for duplicate property assignment at nesting depth
                if cache.nested_debug[depth][property] then
                    error(`duplicate property {property} at depth {depth}`, 0)
                end
                cache.nested_debug[depth][property] = true
            end

            if type(value) == "function" then 
                if typeof((instance :: any)[property]) == "RBXScriptSignal" then
                    table.insert(cache.events, property) -- add event name to buffer
                    table.insert(cache.events, value :: () -> ()) -- add event listener to buffer
                else
                    implicit_effect.property(instance, property, value :: () -> ()) -- create implicit effect for property
                end
            else
                (instance :: any)[property] = value -- set property
            end    
        elseif type(property) == "number" then
            if type(value) == "function" then
                implicit_effect.children(instance, value :: () -> ArrayOrV<Instance>) -- bind children
            elseif type(value) == "table" then
                if is_action(value) then
                    table.insert(cache.actions[(value :: any).priority], (value :: any).callback :: () -> ()) -- add action to buffer
                elseif flags.defer_nested_properties then
                    table.insert(cache.nested_stack, value :: {})
                    table.insert(cache.nested_stack, depth + 1) -- push table to stack for later processing
                else
                    process_properties(value :: Map<unknown, unknown>, instance, cache, depth + 1)
                end
            else
                (value :: Instance).Parent = instance -- parent child
            end
        end
    end
end

-- applies table of nested properties to an instance using full vide semantics
local function apply<T>(instance: T & Instance, properties: { [unknown]: unknown }): T
    if not properties then
        error "attempt to call a constructor returned by create() with no properties"
    end

    -- queue parent assignment if any for last
    local parent: unknown = properties.Parent 

    local caches = borrow_cache()
    local events = caches.events
    local actions = caches.actions
    local nested_debug = caches.nested_debug
    local nested_stack = caches.nested_stack

    -- process all properties
    local depth = 1
    repeat
        process_properties(properties, instance, caches, depth)
        depth = table.remove(nested_stack) :: number
        properties = table.remove(nested_stack) :: {}
    until not properties

    for i = 1, #events, 2 do
        local event_name = events[i]
        local event_listener = events[i + 1]
        ;(instance :: any)[event_name]:Connect(event_listener)
    end

    for _, queued in next, actions do
        for _, callback in next, queued do
            callback(instance)
        end
    end

    if parent then
        if type(parent) == "function" then
            implicit_effect.parent(instance, parent :: () -> Instance)
        else
            instance.Parent = parent :: Instance
        end
    end

    table.clear(events)
    for _, queued in next, actions do table.clear(queued) end
    if flags.strict then table.clear(nested_debug) end
    table.clear(nested_stack)

    return_cache(caches)

    return instance
end

return apply
