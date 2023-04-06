------------------------------------------------------------------------------------------
-- vide/applyProperties.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
local wrapped = graph.wrapped

local throw = require(script.Parent.throw)
local bind = require(script.Parent.bind)
local Types = require(script.Parent.Types)

local function applyProperty(instance: Instance, property: string, value: unknown)
    
end

local function applyProperties<T>(instance: T & Instance, properties: { [string|Types.Symbol<unknown> ]: unknown }): T
    local parent: unknown = properties.Parent 
    if parent then properties.Parent = nil end

    local eventBuffer: { [(Instance, () -> ()) -> ()]: () -> () } = {} -- connect events after setting properties
    local postCreation: (Instance) -> ()? = nil -- buffer for post-creation callback

    for property, value in next, properties do
        if type(property) == "string" then
            if wrapped(value) then
                bind.property(value :: State<unknown>, instance, property)
            else
                (instance :: any)[property] = value
            end    
        elseif type(property) == "table" then
            local priority = property.priority
            if priority == 1 then
                property.run(instance, value)
            elseif priority == 2 then
                eventBuffer[property.run] = value :: () -> ()
            elseif priority == 3 then
                assert(not postCreation)
                postCreation = value :: () -> ()
            else
                error("invalid priority")
            end
        else throw(`Invalid property { tostring(property) }, expected string or symbol`) end
    end

    for fn, v in next, eventBuffer do
        fn(instance, v)   
    end

    if parent then
        applyProperty(instance, "Parent", parent)
        if wrapped(parent) then
            bind.parent(parent :: State<Instance?>, instance)
        else
            instance.Parent = parent :: Instance
        end
    end

    if postCreation then postCreation(instance) end

    return instance
end

return applyProperties
