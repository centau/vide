--------------------------------------------------------------------------------------------------------------
-- vide/bind.lua
--------------------------------------------------------------------------------------------------------------

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

function setup(instance: Instance, deriver: () -> unknown, setter: (Instance) -> ())
    if flags.strict then
        local fn = setter
        local trace = traceback()
        setter = function(instance)
            local ok, err: string? = pcall(fn, instance)
            if not ok then warn(`error occured updating state binding:\n{err}\nset from:{trace}`) end
        end
    end

    local nodes = table.clone((capture(setter :: (Instance) -> unknown, instance)))

    for _, node in next, nodes do
        set_effect(node, setter, instance)
    end
    

    bindcount += 1
    local key = bindcount
    
    weak[key] = instance

    local function ref()
        local _ = nodes -- prevent gc of state while instance exists
        local instance = weak[key] :: Instance
        hold[key] = instance.Parent and instance or nil -- prevent gc of instance while parented
    end

    ref()
    instance:GetPropertyChangedSignal("Parent"):Connect(ref)
end

local function bind_property(instance: Instance, property: string, fn: () -> unknown)
    setup(instance, fn, function(instance_weak: any)
        instance_weak[property] = fn()
    end)
end

local function bind_parent(instance: Instance, fn: () -> Instance?)
    instance.Destroying:Connect(function()
        instance= nil :: any -- allow gc when destroyed
    end)
    setup(instance, fn, function(instance)
        local _ = instance -- state will strongly reference instance when parent is bound
        instance.Parent = fn()    
    end)
end

local function bind_children(parent: Instance, fn: () -> { Instance })
    local currentChildrenSet: { [Instance]: true } = {} -- cache of all children parented before update
    local newChildrenSet: { [Instance]: true } = {} -- cache of all children parented after update

    setup(parent, fn, function(parent_weak)
        local newChildren = fn() -- all (and only) children that should be parented after this update
        if newChildren and type(newChildren) ~= "table" then
            throw(`Cannot parent instance of type { type(newChildren) } `)
        end

        if newChildren then
            for _, child in next, newChildren do
                newChildrenSet[child] = true -- record child set from this update
                if not currentChildrenSet[child] then
                    child.Parent = parent_weak -- if child wasn't already parented then parent it
                else 
                    currentChildrenSet[child] = nil -- remove child from cache if it was already in cache
                end
            end
        end

        for child in next, currentChildrenSet do
            child.Parent = nil -- unparent all children that weren't in the new children set
        end

        table.clear(currentChildrenSet) -- clear cache, preserve capacity
        currentChildrenSet, newChildrenSet = newChildrenSet, currentChildrenSet
    end)
end

return {
    property = bind_property,
    parent = bind_parent,
    children = bind_children,
}
