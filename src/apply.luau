if not game then script = require "test/relative-string" end
local typeof = game and typeof or require "test/mock".typeof :: never
local Vector2 = game and Vector2 or require "test/mock".Vector2 :: never
local UDim2 = game and UDim2 or require "test/mock".UDim2 :: never

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)
local bind = require(script.Parent.bind)
local _, is_action = require(script.Parent.action)()
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>

-- buffer of event -> callback to connect after properties are set
local event_buffer: { [string]: () -> () } = {}

-- buffer of priority -> callback to run after events are connected
local action_buffers = {} :: { { (Instance) -> () } }
setmetatable(action_buffers :: any, {
    __index = function(_, i: number)
        action_buffers[i] = {}
        return action_buffers[i]
    end
})

-- cache used in strict mode to detect duplicate property sets at same nesting levels
local nested_debug_cache: { [number]: { [string]: true } } = {}
setmetatable(nested_debug_cache :: any, {
    __index = function(_, i: number)
        nested_debug_cache[i] = {}
        return nested_debug_cache[i]
    end
})

-- a stack used in place of a recursive function to process nesting layers one at a time
-- enforces the behavior of deeper-nested properties taking precedence of lesser-nested ones
-- each nested table occupies two indexes, reference to table itself and the depth number
-- e.g. props = { t1 = { t3 = {} }, t2 = {} } -> { t1, 1, t2, 1, t3, 2 }
local nested_stack = {} :: { {} | number }

-- todo: solution without manual updating of this table
-- map of datatype names to class default constructor for aggregate initialization
local aggregates = {}

for i, v in next, {
    Vector2 = Vector2,
    UDim2 = UDim2,
    UDim = UDim,
    Rect = Rect,
    Color3 = Color3
} do
    aggregates[i] = v.new
end

-- processes a potentially nested table of values to assign to an instance
local function process_nested(instance: Instance, properties: { [unknown]: unknown })
    local strict = flags.strict

    table.clear(nested_stack)
    if strict then table.clear(nested_debug_cache) end

    local depth = 1

    repeat
        for property, value in properties do
            if type(property) == "string" then
                if strict then -- check for duplicate prop assignment at nesting layer
                    if nested_debug_cache[depth][property] then
                        throw(`duplicate property {property} at depth {depth}`)
                    end
                    nested_debug_cache[depth][property] = true
                end

                if type(value) == "table" then -- attempt aggregate init
                    local ctor = aggregates[typeof((instance :: any)[property])]
                    if ctor == nil then
                        throw(`cannot aggregate construct type {typeof(value)} for property {property}`)
                    end
                    (instance :: any)[property] = ctor(unpack(value :: {}))
                elseif type(value) == "function" then 
                    if typeof((instance :: any)[property]) == "RBXScriptSignal" then
                        event_buffer[property] = value  :: () -> () -- add event to buffer
                    else
                        bind.property(instance, property, value :: () -> ()) -- bind source
                    end
                else
                    (instance :: any)[property] = value -- set property
                end    
            elseif type(property) == "number" then
                if type(value) == "function" then
                    bind.children(instance, value :: () -> { Instance }) -- bind children
                elseif type(value) == "table" then
                    if is_action(value) then
                        table.insert(action_buffers[(value :: any).priority], (value :: any).callback :: () -> ()) -- add action to buffer
                    else
                        table.insert(nested_stack, depth + 1) -- push table to stack for later processing
                        table.insert(nested_stack, value :: {})
                    end
                else
                    (value :: Instance).Parent = instance -- parent child
                end
            end
        end

        -- pop next nested table off stack
        properties = table.remove(nested_stack) :: {}
        depth = table.remove(nested_stack) :: number

    until not properties
end

-- applies table of nested properties to an instance using full vide semantics
local function apply<T>(instance: T & Instance, properties: { [unknown]: unknown }): T
    -- queue parent assignment if any for last
    local parent: unknown = properties.Parent 
    if parent then properties.Parent = nil end

    -- reset buffers
    table.clear(event_buffer)
    for _, buffer in next, action_buffers do
        table.clear(buffer)
    end

    -- process all properties for immediate setting or buffering
    process_nested(instance, properties)

    -- connect buffered events
    for event, fn in next, event_buffer do
        (instance :: any)[event]:Connect(fn)   
    end

    -- run buffered actions respecting their priorities
    for _, buffer in next, action_buffers do
        for _, callback in next, buffer do
            callback(instance)
        end
    end

    -- finally set parent if any
    if parent then
        if type(parent) == "function" then
            error("cannot set parent to state")
        else
            instance.Parent = parent :: Instance
        end
    end

    return instance
end

return apply
