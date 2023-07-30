------------------------------------------------------------------------------------------
-- vide/apply.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>

local throw = require(script.Parent.throw)
local bind = require(script.Parent.bind)

local function recurse(instance: Instance, properties: { [unknown]: unknown }, event_buffer)
    for property, value in properties do
        if type(value) == "table" then
            recurse(instance, value :: {}, event_buffer)
        elseif type(property) == "string" then
            if type(value) == "function" then
                if typeof((instance :: any)[property] == "RBXScriptSignal") then
                    event_buffer[property] = value 
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

    local event_buffer: { [string]: () -> () } = {} -- connect events after setting properties

    recurse(instance, properties, event_buffer)

    for event, fn in next, event_buffer do
        (instance :: any)[event]:Connect(fn)   
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
