local typeof = typeof
local Vector2 = Vector2
local UDim2 = UDim2

if not game then
    script = require "test/relative-string"
    typeof = require "test/mock".typeof
    Vector2 = require "test/mock".Vector2
    UDim2 = require "test/mock".UDim2
end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)
local bind = require(script.Parent.bind)
local _, is_action = require(script.Parent.action)()
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>

local event_buffer: { [string]: () -> () } = {}
local action_buffers = {} :: { { () -> () } }

setmetatable(action_buffers :: any, {
    __index = function(_, i: number)
        action_buffers[i] = {}
        return action_buffers[i]
    end
})

local nested_debug_cache: { [number]: { [string]: true } } = {}

setmetatable(nested_debug_cache :: any, {
    __index = function(_, i: number)
        nested_debug_cache[i] = {}
        return nested_debug_cache[i]
    end
})

local nested_stack = {} :: { {} | number }

-- todo
local classes = {
    Vector2 = Vector2,
    UDim2 = UDim2,
    UDim = UDim2,
    Rect = Rect,
    Color3 = Color3
}

local function get_class(v: unknown): { new: (...any) -> () }
    return classes[typeof(v)]
end

local function process(instance: Instance, properties: { [unknown]: unknown })
    local strict = flags.strict

    table.clear(nested_stack)
    if strict then table.clear(nested_debug_cache) end

    local depth = 1

    repeat
        for property, value in properties do
            if type(property) == "string" then
                if strict then
                    if nested_debug_cache[depth][property] then
                        throw(`duplicate property {property} at depth {depth}`)
                    end
                    nested_debug_cache[depth][property] = true
                end

                if type(value) == "table" then
                    local class = get_class((instance :: any)[property])
                    if class == nil then
                        throw(`cannot aggregate construct type {typeof(value)} for property {property}`)
                    end
                    (instance :: any)[property] = class.new(unpack(value :: {}))
                elseif type(value) == "function" then
                    if typeof((instance :: any)[property]) == "RBXScriptSignal" then
                        event_buffer[property] = value  :: () -> ()
                    else
                        bind.property(instance, property, value :: () -> ())
                    end
                else
                    (instance :: any)[property] = value
                end    
            elseif type(property) == "number" then
                if type(value) == "function" then
                    bind.children(instance, value :: () -> { Instance })
                elseif type(value) == "table" then
                    if is_action(value) then
                        table.insert(action_buffers[(value :: any).priority], (value :: any).callback :: () -> ())
                    else
                        table.insert(nested_stack, depth + 1)
                        table.insert(nested_stack, value :: {})
                    end
                else
                    (value :: Instance).Parent = instance
                end
            end
        end

    properties = table.remove(nested_stack) :: {}
    depth = table.remove(nested_stack) :: number

    until not properties
end

local function apply<T>(instance: T & Instance, properties: { [unknown]: unknown }): T
    local parent: unknown = properties.Parent 
    if parent then properties.Parent = nil end

    table.clear(event_buffer)
    for _, buffer in next, action_buffers do
        table.clear(buffer)
    end

    process(instance, properties)

    for event, fn in next, event_buffer do
        (instance :: any)[event]:Connect(fn)   
    end

    for _, buffer in next, action_buffers do
        for _, callback in next, buffer do
            callback()
        end
    end

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
