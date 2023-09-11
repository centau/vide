if not game then script = require "test/relative-string" end
local warn = game and warn or print :: never

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local get_scope = graph.get_scope
local open_scope = graph.open_scope
local close_scope = graph.close_scope
local set_owner = graph.set_owner

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

function create_binding<T>(updater: (T) -> T, binding_data: T)
    -- if flags.strict then
    --     -- wrap setter in function with stack inspection for better error msgs
    --     local fn = setter
    --     local bind_trace = traceback(0)
    --     setter = function(instance)
    --         local ok, err: string? = xpcall(fn, function(err: string)
    --             return err .. "\nsource updated at: " .. traceback(2)
    --         end, instance)
    --         if not ok then warn(`error occured updating {property}: {err}bound at: {bind_trace}`) end
    --     end
    -- end

    local binding = create_node(binding_data)
    binding.effect = updater

    local owner = get_scope()
    assert(owner)

    set_owner(binding, owner)
    open_scope(binding)

    updater(binding_data)

    close_scope()
end

type PropertyBinding = {
    instance: Instance,
    property: string,
    source: () -> unknown
}

local function update_property(p: PropertyBinding)
    (p.instance :: any)[p.property] = p.source()
    return p
end

type ParentBinding = {
    instance: Instance,
    parent: () -> Instance
}

local function update_parent(p: ParentBinding)
    p.instance.Parent = p.parent()
    return p
end

type ChildrenBinding = {
    instance: Instance,
    cur_children_set: { [Instance]: true },
    new_children_set: { [Instance]: true },
    children: () -> { Instance }
}

local function update_children(p: ChildrenBinding)
    local cur_children_set: { [Instance]: true } = p.cur_children_set -- cache of all children parented before update
    local new_child_set: { [Instance]: true } = p.new_children_set -- cache of all children parented after update

    local new_children = p.children() -- all (and only) children that should be parented after this update
    
    if type(new_children) ~= "table" then
        new_children = { new_children }
    end

    if new_children then
        for _, child in next, new_children do
            new_child_set[child] = true -- record child set from this update
            if not cur_children_set[child] then
                child.Parent = p.instance -- if child wasn't already parented then parent it
            else 
                cur_children_set[child] = nil -- remove child from cache if it was already in cache
            end
        end
    end

    for child in next, cur_children_set do
        child.Parent = nil -- unparent all children that weren't in the new children set
    end

    table.clear(cur_children_set) -- clear cache, preserve capacity
    p.cur_children_set, p.new_children_set = new_child_set, cur_children_set

    return p
end

return {
    property = function(instance, property, source)
        return create_binding(update_property, {
            instance = instance,
            property = property,
            source = source
        })
    end,

    parent = function(instance, parent)
        return create_binding(update_parent, {
            instance = instance,
            parent = parent
        })
    end,

    children = function(instance, children)
        return create_binding(update_children, {
            instance = instance,
            cur_children_set = {},
            new_children_set = {},
            children = children
        })
    end
}
