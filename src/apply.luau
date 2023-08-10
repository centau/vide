local typeof = typeof

if not game then
    script = require "test/relative-string"
    typeof = require "test/mock".typeof
end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>

local bind = require(script.Parent.bind)
local _, is_action = require(script.Parent.action)()

local event_buffer: { [string]: () -> () } = {}
local action_buffers = {} :: { { () -> () } }

setmetatable(action_buffers :: any, {
    __index = function(_, i: number)
        action_buffers[i] = {}
        return action_buffers[i]
    end
})

local function recurse(instance: Instance, properties: { [unknown]: unknown })
    for property, value in properties do
        if type(value) == "table" then
            if is_action(value) then
                table.insert(action_buffers[(value :: any).priority], (value :: any).callback :: () -> ())
            else
                recurse(instance, value :: {})
            end
        elseif type(property) == "string" then
            if type(value) == "function" then
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
            else
                (value :: Instance).Parent = instance
            end
        end
    end
end

local function apply<T>(instance: T & Instance, properties: { [unknown]: unknown }): T
    local parent: unknown = properties.Parent 
    if parent then properties.Parent = nil end

    table.clear(event_buffer)
    for _, buffer in next, action_buffers do
        table.clear(buffer)
    end

    recurse(instance, properties)

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
