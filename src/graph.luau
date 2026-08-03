local flags = require "./flags"

export type SourceNode<T> = {
    cache: T,
    [number]: Node<T>
}

export type Node<T> =  {
    cache: T,
    effect: ((T) -> T) | false,
    cleanups: { () -> () } | false,

    context: { [number]: unknown } | false,

    owned: { Node<T> } | false,
    owner: Node<T> | false,

    parents: { SourceNode<T> },
    [number]: Node<T> -- children
}

local scopes = { n = 0 } :: { [number]: Node<any>, n: number } -- scopes stack

local function efn(err: string)
    local trace = debug.traceback(err, 2)

    if string.find(err, "^effect error stacktrace") then -- if effect error is nested
        trace = string.gsub("    " .. trace, "\n", "\n    ") -- indent entire error
    end

    trace ..= "\nsource update stacktrace:"
    return trace
end

local function ycall<T, U>(fn: (T) -> U, arg: T): (boolean, string|U)

    local thread = coroutine.create(xpcall)
    --local function efn(err: string) return debug.traceback(err, 3) end
    local resume_ok, run_ok, result = coroutine.resume(thread, fn, efn, arg)

    assert(resume_ok)

    if coroutine.status(thread) ~= "dead" then
        return false, debug.traceback(thread, "attempt to yield in reactive scope")
    end

    return run_ok, result
end

local function get_scope(): Node<unknown>?
    return scopes[scopes.n]
end

local function assert_stable_scope(): Node<unknown>
    local scope = get_scope()

    if not scope then
        local caller_name = debug.info(2, "n")
        return error(`cannot use {caller_name}() outside a stable or reactive scope`, 0)
    elseif scope.effect then
        error("cannot create a new reactive scope inside another reactive scope", 0)
    end

    return scope
end

local function push_child<T>(parent: SourceNode<any>, child: Node<any>)
    table.insert(parent, child)
    table.insert(child.parents, parent)
end

local function push_scope<T>(node: Node<T>)
    local n = scopes.n + 1
    scopes.n = n
    scopes[n] = node
end

local function pop_scope()
    local n = scopes.n
    scopes.n = n - 1
    scopes[n] = nil
end

local function push_cleanup<T>(node: Node<T>, cleanup: () -> ())
    if node.cleanups then
        table.insert(node.cleanups, cleanup)
    else
        node.cleanups = { cleanup }
    end
end

local function flush_cleanups<T>(node: Node<T>)
    if node.cleanups then
        for _, fn in node.cleanups do
            local ok, err: string? = xpcall(fn, debug.traceback)
            if not ok then error(`cleanup error: {err}`, 0) end
        end

        table.clear(node.cleanups)
    end
end

local function find_and_swap_pop<T>(t: { T }, v: T)
    local i = table.find(t, v) :: number
    local n = #t
    t[i] = t[n]
    t[n] = nil
end

local function unparent<T>(node: Node<T>)
    local parents = node.parents

    for i, parent in parents do
        find_and_swap_pop(parent, node)
        parents[i] = nil
    end
end

local function destroy<T>(node: Node<T>)
    if flags.strict and table.find(scopes, node) then
        error("attempt to destroy an active scope", 0)
    end

    flush_cleanups(node)
    unparent(node)

    if node.owner then
        find_and_swap_pop(node.owner.owned :: { Node<T> }, node)
        node.owner = false
    end

    if node.owned then
        local owned = node.owned
        while owned[1] do destroy(owned[1]) end
    end
end

local function destroy_owned<T>(node: Node<T>)
    if node.owned then
        local owned = node.owned
        while owned[1] do destroy(owned[1]) end
    end
end

local update_queue_n = 0
local in_queue = {}
local update_queue = {} :: { [number]: Node<any> }
local node_deps_left = {} -- any node that goes into the update queue needs to store how many dependencies it's waiting on

local function reset_queue()
    update_queue_n = 0
    table.clear(in_queue)
    table.clear(update_queue)
    table.clear(node_deps_left)
end

local function evaluate_node<T>(node: Node<T>, continue_on_error: boolean) -- if continue_on_error, the calling function wishes to continue even if the update fails (without using pcall)
    if flags.strict then
        if table.find(scopes, node) then
            error("a scope, that should rerun due to the update of a source, is already active", 0)
        end

        local initial_value = node.cache

        for i = 1, 2 do
            local cur_value = node.cache

            flush_cleanups(node)
            destroy_owned(node)

            push_scope(node)
            local ok, new_value = ycall(node.effect :: (T) -> T, cur_value)
            pop_scope()

            if not ok then
                local msg = debug.traceback(`effect error: {new_value}`, 2)
                if continue_on_error then
                    print(msg)
                    return false
                else
                    error(msg, 2)
                end
            end

            node.cache = new_value :: T
        end

        return initial_value ~= node.cache
    else
        local cur_value = node.cache

        flush_cleanups(node)
        destroy_owned(node)

        push_scope(node)
        local ok, new_value = pcall(node.effect :: (T) -> T, cur_value)
        pop_scope()

        if not ok then
            local msg = debug.traceback(`effect error: {new_value}`, 2)
            if continue_on_error then
                print(msg)
                return false
            else
                error(msg, 2)
            end
        end

        node.cache = new_value
        return cur_value ~= new_value
    end
end

local function add_dependency_counts(node)
    for i = 1, #node do
        local child = node[i]
        if not child.owner then continue end -- we won't be updating this anyway
        local deps_left = node_deps_left[child]
        if deps_left then
            node_deps_left[child] = deps_left + 1
        else
            node_deps_left[child] = 1
            add_dependency_counts(child) -- only recurse if we haven't seen this node before
        end
    end
end
local function remove_dependency_counts(node) -- to be called when updating a node if its value remains unchanged
    for i = 1, #node do
        local child = node[i]
        if not node.owner then continue end -- we won't be updating this anyway
        local deps_left = node_deps_left[child]
        if deps_left > 1 then
            node_deps_left[child] = deps_left - 1
        else
            node_deps_left[child] = 0
            -- only recurse if we're removing the last dependency *and* if we aren't planning on updating it
            if not in_queue[child] then
                remove_dependency_counts(child)
            end
        end
    end
end

local function queue_children_for_update<T>(node: SourceNode<T>)
    for i = 1, #node do
        local child = node[i]
        local deps_left = node_deps_left[child]
        if deps_left then
            node_deps_left[child] = deps_left - 1
        else
            -- This can happen if child adds parent as a new dependency after the initial update
            node_deps_left[child] = 0
        end
        if not in_queue[child] then
            in_queue[child] = true
            update_queue_n += 1
            update_queue[update_queue_n] = child
        end
    end
end

local function get_update_queue_length()
    return update_queue_n
end

local function flush_update_queue(from: number)
    while true do
        local i = from
        if i >= update_queue_n then return end -- nothing more to do
        local changed = false
        local moveTo1 = from -- 1 less than where to store an update if we can't process it yet
        while i < update_queue_n do
            i += 1
            local node = update_queue[i]
            -- assert(node.effect)
            if node.owner then
                local deps_left = node_deps_left[node]
                if deps_left > 0 then -- waiting on more dependencies
                    moveTo1 += 1
                    if i ~= moveTo1 then
                        update_queue[moveTo1] = node
                        update_queue[i] = false :: any
                    end
                    continue
                end
                changed = true
                -- Reset in_queue and node_deps_left before evaluation in case the node's depedencies are changed during evaluation (which usually implies an infinite loop, but we have explicit errors for this case)
                in_queue[node] = nil
                node_deps_left[node] = nil
                unparent(node)
                if evaluate_node(node, true) then
                    queue_children_for_update(node)
                else
                    remove_dependency_counts(node)
                end
            else -- otherwise node was cleaned up
                in_queue[node] = nil
                node_deps_left[node] = nil
            end

            update_queue[i] = false :: any
        end
        if moveTo1 == 0 then -- no pending updates
            reset_queue()
            return
        else
            update_queue_n = moveTo1
            if not changed then -- Can occur in recursive updates (where 'from' is > 0)
                if from == 0 then
                    print("Some nodes failed to update", update_queue, node_deps_left, debug.traceback())
                    reset_queue()
                end
                return
            end
        end
    end
end

local function update_descendants<T>(root: SourceNode<T>)
    add_dependency_counts(root)
    local n0 = update_queue_n
    queue_children_for_update(root)

    if flags.batch then return end

    flush_update_queue(n0)
end

local function push_scope_as_child_of<T>(node: SourceNode<T>)
    local scope = get_scope()
    if scope and scope.effect then -- do not track nodes with no effect
        push_child(node, scope)
    end
end

local function create_node<T>(owner: false | Node<any>, effect: false | (T) -> T, value: T): Node<T>
    local node: Node<T> = {
        cache = value,
        effect = effect,
        cleanups = false,

        context = false,

        owner = owner,
        owned = false,

        parents = {},
    }

    if owner then
        if owner.owned then
            table.insert(owner.owned, node)
        else
            owner.owned = { node }
        end
    end

    return node
end

local function create_source_node<T>(value: T): SourceNode<T>
    return { cache = value }
end

local function get_children<T>(node: Node<T>): { Node<unknown> }
    return { unpack(node) } :: { Node<any> }
end

local function set_context<T>(node: Node<T>, key: number, value: unknown)
    if node.context then
        node.context[key] = value
    else
        node.context = { [key] = value }
    end
end

return table.freeze {
    push_scope = push_scope,
    pop_scope = pop_scope,
    evaluate_node = evaluate_node,
    get_scope = get_scope,
    assert_stable_scope = assert_stable_scope,
    push_cleanup = push_cleanup,
    destroy = destroy,
    flush_cleanups = flush_cleanups,
    push_scope_as_child_of = push_scope_as_child_of,
    update_descendants = update_descendants,
    push_child = push_child,
    create_node = create_node,
    create_source_node = create_source_node,
    get_children = get_children,
    flush_update_queue = flush_update_queue,
    get_update_queue_length = get_update_queue_length,
    set_context = set_context,
    scopes = scopes,

    q = update_queue
}
