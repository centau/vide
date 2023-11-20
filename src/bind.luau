if not game then script = require "test/relative-string" end

local trace = require(script.Parent.trace)
local flags = require(script.Parent.flags)
local graph = require(script.Parent.graph)
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local assert_owning_scope = graph.assert_owning_scope
local evaluate_node = graph.evaluate_node
local set_owner = graph.set_owner

function create_binding<T>(updater: (T) -> T, binding: T)
    if flags.strict then
        -- track bind creation trace
        local fn = updater
        local bind_trace = debug.traceback(nil, trace()-1)
        updater = function(...)
            local ok, result = xpcall(fn, function(err: string)
                return err
            end, ...)

            if not ok then
                local btype =
                    if (binding :: any).property then (binding :: any).property
                    elseif (binding :: any).parent then "Parent"
                    else "children"
                error(`PROPERTY BINDING ERROR: Property {btype}\n{result}\nBIND CREATION TRACE:\n{bind_trace}`, 0)
            end

            return result
        end
    end

    local owner = assert_owning_scope()
    
    local node = create_node(binding, updater)

    set_owner(node, owner)
    evaluate_node(node)
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
    children: () -> Instance | { Instance }
}

local function update_children(p: ChildrenBinding)
    local cur_children_set: { [Instance]: true } = p.cur_children_set -- cache of all children parented before update
    local new_child_set: { [Instance]: true } = p.new_children_set -- cache of all children parented after update

    local new_children = p.children() -- all (and only) children that should be parented after this update
    
    if type(new_children) ~= "table" then
        new_children = { new_children }
    end

    if new_children then
        for _, child in next, new_children :: { Instance } do
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
