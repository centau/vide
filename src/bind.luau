local warn = warn -- todo

if not game then
    script = (require :: any) "test/wrap-require"
    warn = print
end

local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local get = graph.get
local set_effect = graph.set_effect
local capture = graph.capture

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)

local hold: { Instance? } = {}
local weak: { Instance? } = setmetatable({}, { __mode = "v" }) :: any 
local bindcount = 0

local srcs do
    local src1 = debug.info(1, "s")
    local srctrunc = string.sub(src1, 1, #src1-4)

    srcs = {
        src1,
        srctrunc .. "apply",
        srctrunc .. "create",
    }
end

local function traceback() -- ensures trace begins outside of any vide library file
    local s = 1
    repeat
        s += 1
        local src = debug.info(s, "s")
    until not table.find(srcs, src)
    return debug.traceback("", s)
end

function setup(instance: Instance, setter: (Instance) -> ())
    if flags.strict then
        local fn = setter
        local trace = traceback()
        setter = function(instance)
            local ok, err: string? = pcall(fn, instance)
            if not ok then warn(`error occured updating state binding:\n{err}\nset from:{trace}`) end
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

-- todo: move `fn` as arg?

local function bind_property(instance: Instance, property: string, fn: () -> unknown)
    setup(instance, function(instance_weak: any)
        instance_weak[property] = fn()
    end)
end

local function bind_parent(instance: Instance, fn: () -> Instance?)
    instance.Destroying:Connect(function()
        instance= nil :: any -- allow gc when destroyed
    end)
    setup(instance, function(instance)
        local _ = instance -- state will strongly reference instance when parent is bound
        instance.Parent = fn()    
    end)
end

local function bind_children(parent: Instance, fn: () -> { Instance })
    local current_child_set: { [Instance]: true } = {} -- cache of all children parented before update
    local new_child_set: { [Instance]: true } = {} -- cache of all children parented after update

    setup(parent, function(parent_weak)
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
