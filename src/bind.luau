local warn = warn

if not game then
    script = require "test/relative-string"
    warn = print
end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local set_effect = graph.set_effect
local capture = graph.capture

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)

local hold: { Instance? } = {}
local weak: { Instance? } = setmetatable({}, { __mode = "v" }) :: any 
local bindcount = 0

local root do
    local src = debug.info(1, "s")
    root = string.sub(src, 1, #src - 5)
end

local function traceback(skips: number) -- ensures trace begins outside of any vide library file
    local s = 1

    repeat
        s += 1
        local path = debug.info(s, "s")

        local found = not string.find(path, root)

        if found then
            skips -= 1
        end
    until found and skips < 0

    return debug.traceback(nil, s)
end

function setup(instance: Instance, debug_msg: string, setter: (Instance) -> ())
    if flags.strict then
        local fn = setter
        local bind_trace = traceback(0)
        setter = function(instance)
            local ok, err: string? = xpcall(fn, function(err: string)
                return err .. "\nsource updated at: " .. traceback(2)
            end, instance)
            if not ok then warn(`error occured updating {debug_msg}: {err}bound at: {bind_trace}`) end
        end
    end

    local nodes = (capture(setter :: () -> unknown, instance))

    for _, node in next, nodes do
        set_effect(node, setter, instance)
    end

    bindcount += 1
    local key = bindcount
    
    weak[key] = instance

    local function ref()
        local _ = setter
        local instance = weak[key] :: Instance
        hold[key] = instance.Parent and instance or nil -- prevent gc of instance while parented
    end

    ref()
    instance:GetPropertyChangedSignal("Parent"):Connect(ref)
end

local function bind_property(instance: Instance, property: string, fn: () -> unknown)
    setup(instance, property, function(instance_weak: any)
        instance_weak[property] = fn()
    end)
end

local function bind_parent(instance: Instance, fn: () -> Instance?)
    instance.Destroying:Connect(function()
        instance = nil :: any -- allow gc when destroyed
    end)

    setup(instance, "Parent", function(instance)
        local _ = instance -- state will strongly reference instance when parent is bound
        instance.Parent = fn()    
    end)
end

local function bind_children(parent: Instance, fn: () -> { Instance })
    local current_child_set: { [Instance]: true } = {} -- cache of all children parented before update
    local new_child_set: { [Instance]: true } = {} -- cache of all children parented after update

    setup(parent, "Children", function(parent_weak)
        local new_childs = fn() -- all (and only) children that should be parented after this update
        if new_childs and type(new_childs) ~= "table" then
            throw(`Cannot parent instance of type { type(new_childs) } `)
        end

        if new_childs then
            for _, child in next, new_childs do
                new_child_set[child] = true -- record child set from this update
                if not current_child_set[child] then
                    child.Parent = parent_weak -- if child wasn't already parented then parent it
                else 
                    current_child_set[child] = nil -- remove child from cache if it was already in cache
                end
            end
        end

        for child in next, current_child_set do
            child.Parent = nil -- unparent all children that weren't in the new children set
        end

        table.clear(current_child_set) -- clear cache, preserve capacity
        current_child_set, new_child_set = new_child_set, current_child_set
    end)
end

return {
    property = bind_property,
    parent = bind_parent,
    children = bind_children,
}
