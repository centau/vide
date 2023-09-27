if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)

export type StartNode<T> = {
    cache: T,
    [number]: Node<T>
}

export type Node<T> =  {
    cache: T,
    effect:  ((T) -> T) | false,
    cleanups: { () -> () } | false,

    owned: { Node<T> } | false,
    owner: Node<T> | false,

    parents: { StartNode<T> },
    [number]: Node<T> -- children
}

-- reactive scope stack
local scopes = { n = 0 } :: { [number]: Node<any>, n: number }

local function ycall<T, U>(fn: (T) -> U, arg: T): (boolean, string|U)
    local thread = coroutine.create(pcall)
    local resume_ok, run_ok, result = coroutine.resume(thread, fn, arg)

    assert(resume_ok)
        
    if coroutine.status(thread) ~= "dead" then
        return false, "attempt to yield in reactive scope"
    end

    return run_ok, result
end

local function get_scope(): Node<unknown>?
    return scopes[scopes.n]
end

local function get_owning_scope(): Node<unknown>
    local scope = get_scope()
    if not scope then
        local caller_name = debug.info(2, "n")
        return throw(`cannot use {caller_name}() in non-reactive scope, must be used within a root() or mount() callback`)
    elseif scope.effect then
        throw("reactive scope is not an owning scope; new effects cannot be created in side-effects")
    end
    return scope
end

local function add_child<T>(parent: StartNode<any>, child: Node<any>)
    table.insert(parent, child)
    table.insert(child.parents, parent)
end

local function set_owner(node: Node<any>, owner: Node<any>)
    node.owner = owner
    if owner.owned then
        table.insert(owner.owned, node)
    else
        owner.owned = { node }
    end
end

local function open_scope<T>(node: Node<T>)
    local n = scopes.n + 1
    scopes.n = n
    scopes[n] = node
end

local function close_scope()
    local n = scopes.n
    scopes.n = n - 1
    scopes[n] = nil
end

local function add_cleanup<T>(node: Node<T>, cleanup: () -> ())
    if node.cleanups then
        table.insert(node.cleanups, cleanup)
    else
        node.cleanups = { cleanup }
    end
end

local function run_cleanups<T>(node: Node<T>)
    if node.cleanups then
        for _, fn in next, node.cleanups do
            local ok, err: string? = pcall(fn)
            if not ok then throw(`cleanup error: {err}`) end
        end
        table.clear(node.cleanups)
    end
end

local function find_and_swap_pop<T>(t: { T }, v: T)
    local idx = table.find(t, v)
    assert(idx, "value not found")
    local n = #t
    t[idx] = t[n]
    t[n] = nil
end

local function remove_child<T>(parent: StartNode<T>, child: Node<T>)
    find_and_swap_pop(parent, child)
end

local function remove_owner<T>(node: Node<T>)
    local owner = node.owner :: Node<T>
    if node.owner and owner.owned then
        find_and_swap_pop(owner.owned, node)
    end
end

local function unparent<T>(node: Node<T>)
    local parents = node.parents

    for i, parent in next, parents do
        remove_child(parent, node)
        parents[i] = nil
    end
end

local function destroy<T>(node: Node<T>)
    run_cleanups(node)
    unparent(node)
    remove_owner(node)

    if node.owned then
        local owned = node.owned
        while owned[1] do destroy(owned[1]) end
    end
    while node[1] do destroy(node[1]) end
end

local function destroy_owned<T>(node: Node<T>)
    if node.owned then
        while node.owned[1] do destroy(node.owned[1]) end
    end
end

local update_queue = { n = 0 } :: { n: number, [number]: Node<any> }

local function evaluate_node<T>(node: Node<T>)
    local cur_value = node.cache

    if flags.strict then
        run_cleanups(node)
        destroy_owned(node)

        open_scope(node)

        local ok, new_value = ycall(node.effect :: (T) -> T, cur_value)
        
        close_scope()
        
        if not ok then throw(new_value :: string) end

        node.cache = new_value :: T
    end

    run_cleanups(node)
    destroy_owned(node)

    open_scope(node)

    local ok, new_value = pcall(node.effect :: (T) -> T, node.cache)

    close_scope()

    if not ok then
        table.clear(update_queue)
        update_queue.n = 0
        throw(`side-effect error from source update\n{new_value}`)
    end

    node.cache = new_value

    return cur_value ~= new_value -- node has changed value
end

local function update_from<T>(node: StartNode<T>, n0: number)
    if not node[1] then return end

    local n = n0

    -- unparent all children and queue for eval
    do
        local child = node[1]
        while child do
            --assert(child.parents.owner)
            unparent(child)
            n += 1
            update_queue[n] = child
            child = node[1]
        end
    end

    update_queue.n = n

    -- evaluate all queued children
    for i = n0 + 1, n do
        local child = update_queue[i]
        assert(type(child.effect) == "function")

        if evaluate_node(child) then
            update_from(child, n)
        end

        update_queue[i] = false :: any -- false instead of nil to avoid sparse
    end

    update_queue.n = n0
end

local function update<T>(node: StartNode<T>)
    update_from(node, update_queue.n)
end

local function track<T>(node: StartNode<T>)
    local scope = get_scope()
    if scope and type(scope.effect) == "function" then -- do not track nodes with no effect
        add_child(node, scope)
    end
end

local function create_node<T>(value: T, effect: false | (T) -> T): Node<T>
    return {
        cache = value,
        effect = effect,
        cleanups = false,

        owner = false,
        owned = false,

        parents = {},
    }
end

local function create_start_node<T>(value: T): StartNode<T>
    return { cache = value }
end

local function get_children<T>(node: Node<T>): { Node<unknown> }
    return { unpack(node) } :: { Node<any> }
end

return table.freeze {
    open_scope = open_scope,
    close_scope = close_scope,
    evaluate_node = evaluate_node,
    get_scope = get_scope,
    get_owning_scope = get_owning_scope,
    add_cleanup = add_cleanup,
    set_owner = set_owner,
    destroy = destroy,
    run_cleanups = run_cleanups,
    track = track,
    update = update,
    add_child = add_child,
    create_node = create_node,
    create_start_node = create_start_node,
    get_children = get_children,
    scopes = scopes
}
