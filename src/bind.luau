if not game then script = require "test/relative-string" end
local warn = game and warn or print :: never

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create = graph.create
local init_scope = graph.init_scope
local close_scope = graph.close_scope
local add_child = graph.add_child
local capture = graph.capture

--[[

Roblox instances in Luau are referenced using a kind of userdata proxy,
this proxy can be garbage collected independently from the actual instance, even
if the instance is still parented. Since reactive bindings allow the garbage
collection of instances, this proxy can can garbage collected while the instance
is still parented, causing the binding to be lost and no longer update the
instance on changes.

Vide's solution to this is to hold the proxy in memory as long as the instance
is parented to the datamodel by using `GetPropertyChanged("Parent")` to add or
remove the proxy from a table whose sole purpose is to strongly reference
proxies.

todo: investigate behavior in case B is parented to A, and A has no parent or reference, and B has a binding.

]]



-- todo: replace with throw's method
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

function bind(instance: Instance, property: string, setter: (Instance) -> ())
    if flags.strict then
        -- wrap setter in function with stack inspection for better error msgs
        local fn = setter
        local bind_trace = traceback(0)
        setter = function(instance)
            local ok, err: string? = xpcall(fn, function(err: string)
                return err .. "\nsource updated at: " .. traceback(2)
            end, instance)
            if not ok then warn(`error occured updating {property}: {err}bound at: {bind_trace}`) end
        end
    end

    local binding = create(instance)

    init_scope(binding)

    -- run setter to capture any nodes being depended on
    local nodes = (capture(setter :: () -> unknown, instance))

    close_scope()

    binding.effect = setter

    -- register the setter as a side-effect of each node
    for _, node in next, nodes do
        add_child(node, binding)
    end
end

local function bind_property(instance: Instance, property: string, fn: () -> unknown)
    bind(instance, property, function(instance_weak: any)
        instance_weak[property] = fn()
    end)
end

local function bind_parent(instance: Instance, fn: () -> Instance?)
    instance.Destroying:Connect(function()
        instance = nil :: any -- allow gc when destroyed
    end)

    bind(instance, "Parent", function(instance)
        local _ = instance -- state will strongly reference instance when parent is bound
        instance.Parent = fn()    
    end)
end

local function bind_children(parent: Instance, fn: () -> { Instance })
    local current_child_set: { [Instance]: true } = {} -- cache of all children parented before update
    local new_child_set: { [Instance]: true } = {} -- cache of all children parented after update

    bind(parent, "Children", function(parent_weak)
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
