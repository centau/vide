local graph = require "./graph"
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local assert_stable_scope = graph.assert_stable_scope
local evaluate_node = graph.evaluate_node
local push_cleanup = graph.push_cleanup
local destroy = graph.destroy

local function update_property_effect(p: {
    instance: Instance,
    property: string,
    source: () -> unknown  
})
    (p.instance :: any)[p.property] = p.source()
    return p
end

local function update_parent_effect(p: {
    instance: Instance,
    source: () -> Instance
})
    p.instance.Parent = p.source()
    return p
end

-- todo: investigate if "count" method used in indexes() and values() can improve performance here
local function update_children_effect(p: {
    instance: Instance,
    owner: Node<any>,
    cur_children_set: { [Instance]: true },
    new_children_set: { [Instance]: true },
    cur_nested_scopes: { [() -> unknown]: Node<any> },
    new_nested_scopes: { [() -> unknown]: Node<any> },
    source: () -> Instance | { Instance }
})
    local cur_children_set: { [Instance]: true } = p.cur_children_set -- cache of all children parented before update
    local new_children_set: { [Instance]: true } = p.new_children_set -- cache of all children parented after update
    local cur_nested_scopes = p.cur_nested_scopes
    local new_nested_scopes = p.new_nested_scopes

    local new_children = p.source() -- all (and only) children that should be parented after this update
    
    local function keep_nested_scope(child: Instance | { Instance })
        if type(child) == "table" then
            for _, child in child do
                keep_nested_scope(child)
            end
        elseif type(child) == "function" and cur_nested_scopes[child] then
            new_nested_scopes[child] = cur_nested_scopes[child]
            cur_nested_scopes[child] = nil
        end
    end

    if next(cur_nested_scopes) then
        keep_nested_scope(new_children)

        for _, scope in cur_nested_scopes do
            destroy(scope) -- unparent children of removed nested effects before parenting new children
        end

        table.clear(cur_nested_scopes)
    end

    local function process_child(child: Instance | { Instance })
        if type(child) == "userdata" then
            if new_children_set[child] then return end -- stops redundant reparenting

            new_children_set[child] = true -- record child set from this update
            
            if not cur_children_set[child] then
                child.Parent = p.instance -- if child wasn't already parented then parent it
            else 
                cur_children_set[child] = nil -- remove child from cache if it was already in cache
            end  
        elseif type(child) == "table" then
            for _, child in child do
                process_child(child)
            end
        elseif type(child) == "function" then
            if new_nested_scopes[child] then return end

            local scope = create_node(p.owner, false, false) -- not owned by this effect so it is kept when this effect reruns
            local node = create_node(scope, update_children_effect, {
                instance = p.instance,
                owner = scope,
                cur_children_set = {},
                new_children_set = {},
                cur_nested_scopes = {},
                new_nested_scopes = {},
                source = child   
            })
    
            push_cleanup(scope, function()
                for child in node.cache.cur_children_set do
                    if child.Parent == p.instance then child.Parent = nil end
                end
            end)

            new_nested_scopes[child] = scope

            evaluate_node(node)
        end
    end

    process_child(new_children)

    for child in cur_children_set do
        if child.Parent == p.instance then child.Parent = nil end -- unparent all children that weren't in the new children set
    end

    table.clear(cur_children_set) -- clear cache, preserve capacity
    p.cur_children_set, p.new_children_set = new_children_set, cur_children_set
    p.cur_nested_scopes, p.new_nested_scopes = new_nested_scopes, cur_nested_scopes

    return p
end

return {
    property = function(instance, property, source)
        local node = create_node(assert_stable_scope(), update_property_effect, {
            instance = instance,
            property = property,
            source = source
        })

        evaluate_node(node)

        return node
    end,

    parent = function(instance, parent)
        local node = create_node(assert_stable_scope(), update_parent_effect, {
            instance = instance,
            source = parent
        })

        evaluate_node(node)
        
        return node
    end,

    children = function(instance, children)
        local owner = assert_stable_scope()
        local node = create_node(owner, update_children_effect, {
            instance = instance,
            owner = owner,
            cur_children_set = {},
            new_children_set = {},
            cur_nested_scopes = {},
            new_nested_scopes = {},
            source = children
        })

        evaluate_node(node)

        push_cleanup(owner, function()
            for child in node.cache.cur_children_set do
                if child.Parent == instance then child.Parent = nil end
            end
        end)

        return node
    end
}
