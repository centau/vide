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
    parents: { owner: StartNode<T>?, [number]: StartNode<T> },
    [number]: Node<T>
}

-- reactive scope stack
local scopes = { n = 0 } :: { [number]: Node<any>, n: number }

-- runs a given callback in a context that Luau does not allow yielding in
local check_for_yield: <T...>(fn: (T...) -> (), T...) -> (boolean, string?) do
    local t = { __mode = "kv" }
    setmetatable(t, t)

    check_for_yield = function(fn, ...: any)
        local args = { ... }

        t.__unm = function(_)
            fn(unpack(args))
        end

        local ok, err: string? = pcall(function()
            local _ = -t
        end)

        return ok, if err == "attempt to yield across metamethod/C-call boundary"
            or err == "thread is not yieldable" then "yield occured"
            else err
    end
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
        throw("owning scope is not stable; are you trying to derive a new source from within a side-effect?")
    end
    return scope
end

local function add_child<T>(parent: StartNode<any>, child: Node<any>)
    table.insert(parent, child)
    table.insert(child.parents, parent)
end

local function set_owner(node: Node<any>, owner: Node<any>)
    node.parents.owner = owner
    table.insert(owner, node)
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

local function remove_child<T>(parent: StartNode<T>, child: Node<T>)
    local idx = table.find(parent, child)
    assert(idx, "child not found")
    local n = #parent
    parent[idx] = parent[n]
    parent[n] = nil
end

local function unparent<T>(node: Node<T>)
    local parents = node.parents

    for i, parent in ipairs(parents) do
        remove_child(parent, node)
        parents[i] = nil
    end
end

local function destroy<T>(node: Node<T>)
    run_cleanups(node)
    unparent(node)

    node.effect = false

    if node.parents.owner then
        remove_child(node.parents.owner, node)
        node.parents.owner = nil
    end

    while node[1] do destroy(node[1]) end
end

local update_queue = {} :: { Node<any> }

local function evaluate_node<T>(node: Node<T>)
    local cur_value = node.cache

    if flags.strict then
        run_cleanups(node)
        open_scope(node)

        local ok, err = check_for_yield(node.effect :: (T) -> T, cur_value)
        
        close_scope()
        
        if not ok then throw(err :: string) end
    end

    run_cleanups(node) -- todo: move in scope?
    open_scope(node)

    local ok, new_value = pcall(node.effect :: (T) -> T, cur_value)

    close_scope()

    if not ok then
        table.clear(update_queue)
        throw(`side-effect error from source update\n{new_value}`)
    end

    node.cache = new_value

    return cur_value ~= new_value -- node has changed value
end

-- todo: case where owner is set from an untrack call within an effectful node, children clearing
local function update_from<T>(node: StartNode<T>, n0: number)
    if not node[1] then return end

    local n = n0

    -- unparent all children and queue for eval
    do
        local child = node[1]
        while child do -- todo: case where child in owner context
            unparent(child)

            n += 1
            update_queue[n] = child

            child = node[1]
        end
    end

    -- evaluate all queued children
    for i = n0 + 1, n do
        local child = update_queue[i] -- todo: error: index boolean
        if not child.effect then continue end

        if evaluate_node(child) then
            update_from(child, n)
        end

        update_queue[i] = false :: any -- false instead of nil to avoid sparse
    end
end

local function update<T>(node: StartNode<T>)
    update_from(node, 0)
end

local function track<T>(node: StartNode<T>)
    local scope = get_scope()
    if scope and scope.effect then -- do not track nodes with no effect
        add_child(node, scope)
    end
end

local function create_node<T>(value: T, effect: false | (T) -> T): Node<T>
    return {
        cache = value,
        effect = effect,
        cleanups = false,
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
