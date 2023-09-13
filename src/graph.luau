if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)

export type StartNode<T> = {
    cache: T,
    children: { Node<T> } | false
}

export type Node<T> =  {
    cache: T,
    owner: Node<T> | false,
    parents: { StartNode<T> },
    children: { Node<T> } | false,
    effect:  ((T) -> T) | false,
    cleanups: { () -> () } | false,
}

local scopes = { n = 0 } :: { [number]: Node<any>, n: number }

local WEAK_VALUES = { __mode = "v" }
local WEAK_KEYS = { __mode = "k" }
local EVALUATION_ERR = "error while evaluating source:\n\n"

-- runs a given callback in a context that Luau does not allow yielding in
local check_for_yield: <T...>(fn: (T...) -> unknown, T...) -> () do
    local t = { __mode = "kv" }
    setmetatable(t, t)

    check_for_yield = function(fn, ...: any)
        local args = { ... }

        t.__unm = function(_)
            fn(unpack(args))
        end

        local ok, err = pcall(function()
            local _ = -t
        end)

        if not ok then
            if err == "attempt to yield across metamethod/C-call boundary" or err == "thread is not yieldable" then
                throw(EVALUATION_ERR .. "cannot yield when deriving node in effecter")
            else
                throw(EVALUATION_ERR .. err)
            end
        end
    end
end

local function get_stack_scope(offset: number): Node<unknown>?
    return scopes[scopes.n - offset]
end

local function get_scope(): Node<unknown>?
    return scopes[scopes.n]
end


local function add_child<T>(parent: StartNode<any>, child: Node<any>)
    if parent.children then
        table.insert(parent.children :: { Node<T> }, child)
    else
        parent.children = { child }
    end
    
    table.insert(child.parents, parent)
end

local function set_owner(node: Node<any>, owner: Node<any>)
    node.owner = owner
    if owner.children then
        table.insert(owner.children :: { Node<any> }, node)
    else
        owner.children = { node }
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

local function remove_child<T>(parent: StartNode<T>, child: Node<T>)
    local children = parent.children :: {}
    local idx = table.find(children :: {}, child)
    
    local n = #children
    children[idx] = children[n]
    children[n] = nil
end

local function unparent<T>(node: Node<T>)
    for _, parent in node.parents do
        remove_child(parent, node)
    end

    table.clear(node.parents)
end

local function destroy<T>(node: Node<T>)
    run_cleanups(node)
    unparent(node)
    if node.owner then remove_child(node.owner, node) end
    node.owner = false
    local children = node.children :: {}
    if children then
        while children[1] do destroy(children[1]) end
    end
end

local function evaluate_node<T>(node: Node<T>)
    local cur_value = node.cache

    run_cleanups(node) -- todo: move in scope?

    open_scope(node)

    local ok, new_value = pcall(node.effect :: (T) -> T, cur_value)

    close_scope()

    if not ok then
        throw(`side-effect error\n{new_value}`)
    end

    node.cache = new_value

    return cur_value ~= new_value -- node has changed value
end

local update_queue = {} :: { Node<any> }

local function update<T>(node: StartNode<T>)
    local children = node.children :: {}
    if not children then return end

    local n0 = #update_queue
    local first_update = n0 == 0
    local n = n0

    if first_update then
        table.clear(update_queue)
    end

    do
        local child = children[1]
        while child do -- todo: case where child in owner context
            unparent(child)

            n += 1
            update_queue[n] = child

            child = children[1]
        end
    end

    for i = n0 + 1, n do
        local child = update_queue[i]
        if not child.effect then continue end

        if evaluate_node(child) then
            update(child)
        end
    end

    if first_update then
        table.clear(update_queue)
    end
end

local function track<T>(node: StartNode<T>)
    local scope = get_scope()
    if scope and scope.effect then -- todo
        add_child(node, scope)
    end
end

local function create_node<T>(value: T, effect: false | (T) -> T): Node<T>
    local node: Node<T> = {
        cache = value,
        owner = false,
        effect = effect,
        cleanups = false :: false,
        parents = {},
        children = false :: false
    }

    return node
end

local function get_children<T>(node: Node<T>): { Node<unknown> }
    if not node.children then return {} end

    local children = {}

    for _, child in node.children do
        table.insert(children, child)
    end

    return children :: { Node<any> }
end

local function create_start_node<T>(value: T): StartNode<T>
    return { cache = value, children = false }
end

return table.freeze {
    open_scope = open_scope,
    close_scope = close_scope,
    evaluate_node = evaluate_node,
    get_scope = get_scope,
    get_stack_scope = get_stack_scope,
    add_cleanup = add_cleanup,
    set_owner = set_owner,
    destroy = destroy,
    run_cleanups = run_cleanups,
    track = track,
    update = update,
    add_child = add_child,
    create_node = create_node,
    create_start_node = create_start_node,
    get_children = get_children
}
